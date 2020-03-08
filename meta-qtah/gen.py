#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python37 python37Packages.parsy
#TODO pinning

#this has no design, i just started trying to generate stuff from the inside out, starting with ctors, boolisprop, mkmethod

import xml.etree.ElementTree as ET
import subprocess
import sys

def parseArgs():
  classInclude = sys.argv[1]
  className = classInclude.split("/")[1] #TODO system dependent path separator
  return classInclude, className

def getXML(classInclude):
  xml = subprocess.check_output("./extractor.sh %s" % classInclude, shell=True, stderr=subprocess.DEVNULL)
  tree = ET.fromstring(xml)
  return tree

def getClassElem(tree):
  results = tree.findall('./object-type[@name="%s"]' % className)
  results += tree.findall('./value-type[@name="%s"]' % className) #TODO i have no idea why i need both
  try:
    assert(len(results) == 1)
  except AssertionError as e:
    print(results)
    raise e
  result = results[0]
  return result

def dumpClassXML(elem):
  print(ET.tostring(elem).decode("ascii"))

class BadSig(Exception):
  pass


#TOOD tests
def parseSig(sigstr): #this is adhoc #TODO
  from parsy import string, regex, seq, any_char, ParseError
  # "qt_static_metacall(QObject,QMetaObject::Call,int,void)"
  # "QPushButton(QWidget)"
  until = lambda x: (string(x).should_fail("not %s" % x) >> any_char).many().concat()
#  rettype = regex("[a-zA-Z0-9_]") << string(" x ") #bleh, i couldnt figure out why -> was getting escaped
  rettype = until(" x ") << string(" x ")
  destructor = string("~").optional().map(bool)
  name = regex("[^(]+")
  arg = regex("[^,)]+") << string(",").optional()
  args = string("(") >> arg.many() << string(")")
  try:
    rettype, destructor, name, args = seq(rettype, destructor, name, args).parse(sigstr)
  except ParseError as e:
    print("failed in %s" % sigstr)
    raise e
  return rettype, destructor, name, args

def hoppyArgsFrom(args, isCtor, debug_sig):
  result = []
  length = len(args)
  for i,arg in enumerate(args):
    #TODO idk when this is added to the sig
    if "::" in arg:
      raise BadSig("dont know how to handle ::")
    if arg.startswith("Q"):
      if isCtor and i == length-1 and arg == "QWidget": #heuristic: the last widget argument of a constructor is a parent? #TODO tbh this is a hack
        result += ["ptrT $ objT c_%s" % arg]
      else:
        result += ["objT c_%s" % arg]
    else:
      try:
        result += [ Rules.typelut[arg] ] #TODO WARNING THIS IS A HACK, dunno if pointer or not or what
      except KeyError as e:
        print("failed on %s in %s" % (arg, debug_sig))
        raise BadSig(*e.args)
      #raise NotImplementedError()
  return result

def _parseRetTypeToHoppy(retstr): #TODO i have no idea how tp parse this stuff
  from parsy import string, regex, seq, any_char
  _prefix = (regex("const") << string(" ")).optional()
  _type = regex("[^ *&]+") << string(" ").optional()
  _pointer = string("*").optional()
  prefix, type, pointer = seq(_prefix, _type, _pointer).parse(retstr)
  return prefix, type, pointer

def parseRetTypeToHoppy(retstr):
  prefix, type, pointer = _parseRetTypeToHoppy(retstr)
  try:
    type = Rules.typelut[type]
  except KeyError:
    type = "objT c_%s" % type #TODO , this is going to clash with props and flags and stuff
  hoppystr = "(%s(%s))" % (("ptrT " if pointer else "") + ("constT " if prefix == "const" else ""), type)
  return hoppystr

class Rules:
  typelut = {
    "int" : "intT",
    "bool" : "boolT",
    "void" : "voidT"
    }

  def __init__(self, className):
    self.className = className

  def fsigToHoppy(self, sigstr):
    #TODO hasRetVal?
    #TODO meh
    isCtor = False
    isIsBool = False
    _rettype, destructor, _fname, _args = parseSig(sigstr)
    if _fname == self.className:
      suffix = "N".join(_args)
      fname = "new" + (("With" + suffix) if suffix else "")
      isCtor = True
    elif _fname.startswith("is"): 
      fname = _fname.lstrip("is").lower()
      isIsBool = True
    else:
      fname = _fname

    if isCtor:
      argss = "[ %s ]" % ", ".join(hoppyArgsFrom(_args, isCtor, sigstr))
      return 'mkCtor "%s" %s' % (fname, argss if argss != "[  ]" else "np")
    elif isIsBool:
      return 'mkBoolIsProp "%s"' % fname
    else: #TODO IDK how to distinguish properties
      argss = "[ %s ]" % ", ".join(hoppyArgsFrom(_args, isCtor, sigstr))
      ret = parseRetTypeToHoppy(_rettype)
      return 'mkMethod "%s" %s %s' % (fname, argss if argss != "[  ]" else "np", ret)
      #raise NotImplementedError()

  def _ctors(self, classElem):
    return [x.attrib["signature"] for x in classElem.findall("./function") if x.attrib["signature"].startswith(self.className)]

  def mkCtors(self, classElem):
    ctors = self._ctors(classElem)
    return list(map(self.fsigToHoppy, ctors))

  def _boolisprops(self, classElem):
    return [x.attrib["signature"] for x in classElem.findall("./function") if x.attrib["signature"].startswith("is")]

  def mkBoolIsProps(self, classElem):
    boolisprop = self._boolisprops(classElem)
    return list(map(self.fsigToHoppy, boolisprop))

  def mkRest(self, classElem, ignoreFns):
    def filterfnsByNameOrSig(signatures, ignore):
      keep = []
      for x in signatures:
        _, _, fname, _ = parseSig(x)
        if fname in ignore:
          continue
        keep += [ x ]
      return list(set(keep).difference(set(ignore)))
      #return list(set(signatures).remove(set([])))

    signatures = [x.attrib["signature"] for x in classElem.findall("./function")]
    res = list(
      set(signatures).difference(
        set(self._boolisprops(classElem))
          .union(set(self._ctors(classElem)))
        )
        .intersection(set(filterfnsByNameOrSig(signatures, ignoreFns))) #todo difference might be bettter
      )

    result = []
    failures = []
    for x in res:
      try:
        result += [ self.fsigToHoppy(x) ]
      except BadSig as e:
        failures += [ x ]
        print(e)
        continue
    print("FAILURES ON: %s" % failures)
    return result


classInclude, className = parseArgs()
tree = getXML(classInclude)
classElem = getClassElem(tree)
#TODO: logging
dumpClassXML(classElem)
#Rules(className).

ignoreFns = ["tr", "trUtf8", "metaObject", "qt_metacast", "qt_metacall", "trUtf8", "qt_static_metacall"] + \
  [("void","QPixmap(char)"), ("bool","loadFromData(QByteArray,char,Qt::ImageConversionFlags)")] #qpixmap
