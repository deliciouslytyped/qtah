#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python37 python37Packages.parsy
#TODO pinning

#this has no design, i just started trying to generate stuff from the inside out, starting with ctors, boolisprop, mkmethod

#if copy constructor exists, add Copyable
#if exist name, setName pairs, makeProp?

import xml.etree.ElementTree as ET
import subprocess
import sys
import re
from collections import namedtuple
from enum import Enum
from textwrap import dedent

##method types
Constructor = namedtuple("Constructor", ["signature", "ret", "is_const"])
Destructor = namedtuple("Constructor", ["signature", "ret", "is_const"])
Normal = namedtuple("Normal", ["signature", "ret", "is_const"])
# + ...
##

MethodInfo = namedtuple("MethodInfo", ["signature", "ret", "method_type", "is_const"])
Signature = namedtuple("Signature", ["name", "args", "string_signature"]) #TODO
ReturnType = namedtuple("ReturnType", ["prefix", "type", "pointer"]) #TODO bleh
class MethodType(Enum):
  constructor = "Constructor"
  normal = "Normal"
  destructor = "Destructor"

FeatureSet = namedtuple("FeatureSet", ["spec", "cls", "type", "extra"]) #TODOX
Import = namedtuple("Import", ["path", "imports"])
class SpecFeature(Enum):
  mkCtor = "mkCtor"
  mkMethod = "mkMethod"
  mkBoolIsProp = "mkBoolIsProp"
  np = "np"
  mkProp = "mkProp"
  mkConstMethod = "mkConstMethod"

class GlobalSpecFeature(Enum):
  #stuff used "everywhere", i.e. in the template
  makeClass = "makeClass"
  includeStd = "includeStd"
  addReqIncludes = "addReqIncludes"
  ident = "ident"
  classSetEntityPrefix = "classSetEntityPrefix"

class ClassFeature(Enum):
  pass

class TypeFeature(Enum):
  objT = "objT"
  ptrT = "ptrT"
  constT = "constT"
  voidT = "voidT"
  boolT = "boolT"
  intT = "intT"

class HoppyMethodType(Enum):
  BoolIsProp = 1
  Ctor = 2
  PlainMethod = 3
  ConstMethod = 4 #TODO numbers idk
HoppyMethods = namedtuple("HoppyMethods", [x.name for x in HoppyMethodType])

class BadSig(Exception):
  pass

#################

class App:
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


class Parsing:
  #TODO tests
  #  until = lambda x: (string(x).should_fail("not %s" % x) >> any_char).many().concat()
  def parse_sig(sigstr):
    from parsy import string, regex, seq, any_char, ParseError
    # "qt_static_metacall(QObject,QMetaObject::Call,int,void)"
    # "QPushButton(QWidget)"
    destructor = string("~").optional().map(bool)
    name = regex("[^(]+")
    arg = regex("[^,)]+") << string(",").optional()
    args = string("(") >> arg.many() << string(")")
    try:
      _, name, args = seq(destructor, name, args.map(tuple)).parse(sigstr) #dont need to know about destructor because its cased by the namedtuples
    except ParseError as e:
      raise BadSig(e.args)
    return Signature(name=name, args=args, string_signature=sigstr) #TODO parse more proper #TODO merge with rettype and stop mixing up whats meant by signature

  def parse_ret(retstr): #TODO i have no idea how to parse this stuff
    from parsy import string, regex, seq, any_char, ParseError
    prefix = (regex("const") << string(" ")).optional()
    type = regex("[^ *&]+") << string(" ").optional()
    pointer = string("*").optional()
    try:
      prefix, type, pointer = seq(prefix, type, pointer).parse(retstr)
    except ParseError as e:
      raise BadSig(e.args)
    return ReturnType(prefix=prefix, type=type, pointer=pointer) #TODO bleh

class Convert:
  #TODO handle overloads
  def _mkMethod(func, method_struct):
    fname = method_struct.signature.name
    features, _args, failed = Convert.argsToHoppy(method_struct.signature.args, debuginfo=method_struct) #TODO handle fail
    args = "[ %s ]" % ", ".join(_args)
    try:
      features, ret = Convert.retToHoppy(method_struct.ret)
    except BadSig as e:
      failed += [ (func, method_struct, e) ]
    if failed:
      return [], [], failed
    return features, ['%s "%s" %s %s' % (func, fname, args if args != "[  ]" else "np", ret)], failed

  def methodToHoppy(variant, method_struct):
    #TODO: case over Normal(is.. / ??), Constructor

    #TODO hasRetVal?
    #TODO meh
    if variant == "constructor":
      suffix = "N".join(method_struct.signature.args)
      fname = "new" + (("With" + suffix) if suffix else "")
      features, _args, failed = Convert.argsToHoppy(method_struct.signature.args, isCtor=True, debuginfo=method_struct) #TODO handle fail #TODO pass extra info for debug output
      args = "[ %s ]" % ", ".join(_args)
      return features, ['mkCtor "%s" %s' % (fname, args if args != "[  ]" else "np")], failed

    elif variant == "boolisprop":
      fname = method_struct.signature.name.lstrip("is")
      fname = re.sub("[A-Z]", lambda x: x.group().lower(), fname, count=1) #decapitalize first capital, for camelcasing (wait is this even necessary?) TODO
      return [], ['mkBoolIsProp "%s"' % fname], []

    elif variant == "constmethod":
      return Convert._mkMethod("mkConstMethod", method_struct)

    elif variant == "plainmethod": #TODO IDK how to distinguish properties
      return Convert._mkMethod("mkMethod", method_struct)

    else:
      raise NotImplementedError()


  def retToHoppy(ret_struct): #TODO re: i have no idea how to parse this
    #prefix, type, pointer
    features = list()
    try:
      type = Rules.typelut[ret_struct.type]
      features += [ FeatureSet(spec=set(), cls=set(), type={TypeFeature(type)}, extra=set()) ] #wrote this after the except keyerror, TODO can this keyerror after the previous line?
    except KeyError:
      assert(re.match("Q[a-zA-Z0-9_]+", ret_struct.type))
      type = "objT c_%s" % ret_struct.type #TODO , this is going to clash with props and flags and stuff
      try:
        features += [ FeatureSet(spec=set(), cls=set(), type={TypeFeature.objT}, extra={ModLUT.mkLookupImport("c_%s" % ret_struct.type)})  ] 
      except KeyError as e: #failure on mkLookupImport
        raise BadSig(*e.args, "failed on mkLookupImport c_%s" % ret_struct.type)
    hoppystr = "(%s(%s))" % (("ptrT " if ret_struct.pointer else "") + ("constT " if ret_struct.prefix == "const" else ""), type)
    return [ mergeFeatures(features + [ FeatureSet(spec=set(), cls=set(), type={TypeFeature.ptrT, TypeFeature.constT}, extra=set())] ) ], hoppystr #TODO dynamic

  def _argToHoppy(arg, i, length, isCtor):
    if "::" in arg: #TODO idk when this is added to the sig
      raise BadSig("dont know how to handle ::")
    if arg.startswith("Q"):
      try:
        if isCtor and i == length-1 and arg == "QWidget": #heuristic: the last widget argument of a constructor is a parent? #TODO tbh this is a hack
          return [ FeatureSet(spec=set(), cls=set(), type={TypeFeature.objT, TypeFeature.ptrT}, extra={ModLUT.mkLookupImport("c_%s" % arg)}) ], "ptrT $ objT c_%s" % arg
        else:
          return [ FeatureSet(spec=set(), cls=set(), type={TypeFeature.objT}, extra={ModLUT.mkLookupImport("c_%s" % arg)}) ], "objT c_%s" % arg
      except KeyError as e: #failure on mkLookupImport
        raise BadSig(*e.args, "failed on mkLookupImport c_%s" % arg)
    else:
      try:
        result = Rules.typelut[arg] #TODO WARNING THIS IS A HACK, dunno if pointer or not or what
        return [ FeatureSet(spec=set(), cls=set(), type={TypeFeature(result)}, extra=set()) ], result
      except KeyError as e:
        raise BadSig(*e.args, "failed on %s" % arg)
      #raise NotImplementedError()

  def argsToHoppy(args, debuginfo, isCtor=False): #TODO add another intermediate parsing stage to get structured info at this point instead of processing the strings here
    result, failed, features = list(), list(), list()
    length = len(args)
    for i,x in enumerate(args):
      try:
        _features, _result = Convert._argToHoppy(x, i, length, isCtor)
        features += _features
        result += [ _result ]
      except BadSig as e:
        failed += [ (debuginfo, x, e) ]
        continue
    return features, result, failed

  def mkCtors(methods):
    features, result, failed = list(), list(), list()
    for x in methods:
      _features, _res, _fail = Convert.methodToHoppy("constructor", x)
      result += _res
      failed += _fail
      features += _features
    return features, result, failed

  def mkBoolIsProps(methods):
    features, result, failed = list(), list(), list()
    for x in methods:
      _features, _res, _fail = Convert.methodToHoppy("boolisprop", x)
      result += _res
      failed += _fail
      features += _features
    return features, result, failed

  def mkPlainMethods(methods):
    features, result, failed = list(), list(), list()
    for x in methods:
      _features, _res, _fail = Convert.methodToHoppy("plainmethod", x)
      result += _res
      failed += _fail
      features += _features
    return features, result, failed

  def mkConstMethods(methods):
    features, result, failed = list(), list(), list()
    for x in methods:
      _features, _res, _fail = Convert.methodToHoppy("constmethod", x)
      result += _res
      failed += _fail
      features += _features
    return features, result, failed

  #the features for method types are returned by correlate, this chain only returns features for the signature types
  def hoppyMethodsToStrings(struct):
    features, result, failed = list(), list(), list()

    _features, _result, _failed = Convert.mkBoolIsProps(struct.BoolIsProp)
    result += _result
    features += _features
    failed += _failed

    _features, _result, _failed = Convert.mkCtors(struct.Ctor)
    result += _result
    features += _features
    failed += _failed

    _features, _result, _failed = Convert.mkPlainMethods(struct.PlainMethod)
    result += _result
    features += _features
    failed += _failed

    _features, _result, _failed = Convert.mkConstMethods(struct.ConstMethod)
    result += _result
    features += _features
    failed += _failed

    return mergeFeatures(features), result, failed

class Rules:
  typelut = {
    "int" : "intT",
    "bool" : "boolT",
    "void" : "voidT"
    }

  def __init__(self, className):
    self.className = className

  def genModule(classInfo, features, methods):
    featurestrs = lambda x: [y.value for y in x] #TODO
    #TODO split extraimports
    template = dedent("""\
      module Graphics.UI.Qtah.Generator.Interface.{hsClassModule}.{className} (
        aModule,
        {hsClassName}
        ) where

      import Foreign.Hoppy.Generator.Spec (
        {specfeatures}
        )
      import Foreign.Hoppy.Generator.Spec.ClassFeature (
        {classfeatures}
        )
      import Foreign.Hoppy.Generator.Types (
        {typefeatures}
        )
      {extraimports}
      import Graphics.UI.Qtah.Generator.Module (AModule (AQtModule), makeQtModule)
      import Graphics.UI.Qtah.Generator.Types

      {{-# ANN module "HLint: ignore Use camelCase" #-}}

      aModule =
        AQtModule $
        makeQtModule [ {makeQtModule_path} ]
        [
        qtExport {hsClassName}
        ]

      {hsClassName} =
        addReqIncludes [includeStd "{className}"] $ --TODO I've no idea what this does
        classSetEntityPrefix "" $ --TODO I've no idea what this does
        makeClass (ident "{className}") Nothing --TODO I've no idea what this does
        [ {superclasses} ]
        [ {methods}
        ]
      """)

    return template.format(
        hsClassModule = classInfo.hsClassModule,
        hsClassName = classInfo.hsClassName,
        className = classInfo.className,
        makeQtModule_path = ", ".join(['"%s"' % x for x in classInfo.makeQtModule_path]),
        superclasses = ", ".join(classInfo.hsSuperclasses),
        specfeatures = "\n  , ".join(featurestrs(features.spec) + featurestrs(list(GlobalSpecFeature))),
        classfeatures = "\n  , ".join(featurestrs(features.cls)),
        typefeatures = "\n  , ".join(featurestrs(features.type)),
        extraimports = "\n".join(map(mkImportString, features.extra)),
        methods = "\n  , ".join(methods)
        )

def mkImportString(import_struct): #TODOX
  return ("import " + ".".join(import_struct.path) + " (%s)") % (", ".join(import_struct.imports))

def mergeFeatures(features):
  spec, cls, type, extra = set(), set(), set(), set()
  for x in features:
    spec = spec.union(x.spec)
    cls = cls.union(x.cls)
    type = type.union(x.type)
    extra = extra.union(x.extra)
  return FeatureSet(spec=spec, cls=cls, type=type, extra=extra)

class ClassInfo:
  def __init__(self, path, classElem):
    self.hsClassModule, self.className = ClassModuleRules.lookup(path);
    self.hsClassName = "c_%s" % self.className
    self.makeQtModule_path = [ self.hsClassModule, self.className ]
    self.superclasses = classElem.attrib["baseClasses"].split(", ")
    self.hsSuperclasses = ["c_" + x for x in self.superclasses]
    self.superclassFeatures = mergeFeatures([ FeatureSet(spec=set(), cls=set(), type=set(), extra={ModLUT.mkLookupImport(x)}) for x in self.hsSuperclasses ])

class Correlate:
  def _filterMethodsByNameOrSig(signatures, ignore): #TODO
    keep = []
    for x in signatures:
      if x.signature.string_signature in ignore or x.signature.name in ignore:
        continue
      keep += [ x ]
    return keep

  def _mkMethodStructs(classElem, ignores):
    methods = []
    failed = []
    for x in classElem.findall("./function"):
      try:
       name = Parsing.parse_sig(x.attrib["signature"]).name #TODO is this correct?
       sig = x.attrib["signature"]
       if name in ignores or sig in ignores:
        continue 
       methods += [
          MethodInfo(
            signature=Parsing.parse_sig(x.attrib["signature"]),
            ret=Parsing.parse_ret(x.attrib["return"]),
            method_type=x.attrib["ttype"],
            is_const=True if x.attrib["isConst"] == "true" else False
            )
          ]
      except BadSig as e:
        failed += [ (x, e) ]
    return methods, failed

  #TODO ignores ignore
  def filter_mkMethod(methods, ignore=lambda x: False): #gets passed only the remaining
    result = methods
    features = []
    if result:
       features += [ FeatureSet(spec={SpecFeature.mkMethod}, cls=set(), type=set(), extra=set()) ]
    remaining = set()
    return result, remaining, features

  #left as an example
  def filter_mkCtor(methods, ignore=lambda x: False):
    #TODO decided i cant use these after all
    isCtor = lambda x: x.method_type == MethodType.constructor.value

    result, remaining = list(), list()
    for x in methods:
      if isCtor(x) and not ignore(x):
        result += [ Constructor(signature=x.signature, ret=x.ret, is_const=x.is_const) ]
      else:
        remaining += [ x ]
    features = list()
    if result:
       features += [ FeatureSet(spec={SpecFeature.mkCtor}, cls=set(), type=set(), extra=set()) ]
    return result, remaining, features

  def filter_mkBoolIsProp(methods, ignore=lambda x: False):
    #TODO decided i cant use these after all
    isBoolIsProp = lambda x: x.method_type == MethodType.normal.value and x.signature.name.startswith("is")

    result, _remaining = list(), list()
    for x in methods:
      if isBoolIsProp(x) and not ignore(x):
        result += [ Normal(signature=x.signature, ret=x.ret, is_const=x.is_const) ]
      else:
        _remaining += [ x ]

    names = [ x.signature.name for x in result ]
    remaining = [ x for x in _remaining if "is" + x.signature.name.lstrip("set") not in names] #TODO this isnt really correct. also needs to account for mkProp. TODO: assert consistency; is_ set_ and _ should all be present as appropriate

    features = list()
    if result:
       features += [ FeatureSet(spec={SpecFeature.mkBoolIsProp}, cls=set(), type=set(), extra=set()) ]
    return result, remaining, features

  def filter_mkProp(methods, ignore=lambda x: False):
    raise NotImplementedError()

  def filter_mkConstMethod(methods, ignore=lambda x: False):
    #TODO decided i cant use these after all
    isConstMethod = lambda x: x.method_type == MethodType.normal.value and x.is_const

    result, remaining = list(), list()
    for x in methods:
      if isConstMethod(x) and not ignore(x):
        result += [ Normal(signature=x.signature, ret=x.ret, is_const=x.is_const) ]
      else:
        remaining += [ x ]
    features = list()
    if result:
       features += [ FeatureSet(spec={SpecFeature.mkConstMethod}, cls=set(), type=set(), extra=set()) ]
    return result, remaining, features

  def correlate(classElem, ignores): #TODO ignores
    methods, failed = Correlate._mkMethodStructs(classElem, ignores)
    remaining, features = list(), list()

    res_mkCtor, _remaining, _features = Correlate.filter_mkCtor(methods)
    features += _features
    remaining += [ _remaining ]

    ##TODO idk if this covers everything, but its a start?
    #res_mkProp, prop_remaining, _features = Correlate.filter_mkProp(methods)
    #features += _features
    #remaining += [ prop_remaining ]

    res_mkBoolIsProp, boolisprop_remaining, _features = Correlate.filter_mkBoolIsProp(methods)
    features += _features
    remaining += [ boolisprop_remaining ]

    res_mkConstMethod, _remaining, _features = Correlate.filter_mkConstMethod(methods, ignore=lambda x: not x in boolisprop_remaining)
    features += _features
    remaining += [ _remaining ]

    #havent implemented dtors or cctors yet
    remaining += [ [ x for x in methods if x.method_type not in ["CopyConstructor", "Destructor"]] ]

    #havent implemented event handler handling yet(?)
    remaining += [ [ x for x in methods if not (x.signature.name.endswith("Event") or x.signature.name == "event")] ]

    res_mkMethod, _, _features = Correlate.filter_mkMethod(list(set.intersection(*map(set, remaining))))
    features += _features

    return mergeFeatures(features), HoppyMethods(Ctor=res_mkCtor, BoolIsProp=res_mkBoolIsProp, PlainMethod=res_mkMethod, ConstMethod=res_mkConstMethod), failed


class ClassModuleRules:
  def lookup(path):
    _module, _name = path.split("/")
    if _module == "QtGui":
      return ("Gui", _name)
    elif _module == "QtWidgets":
      return ("Widgets", _name)
    else:
      raise NotImplementedError()
    #return ClassModuleRules.lut[_module][_name] #TODO

class FilterRules:
  ignoreFns = ["tr", "trUtf8", "metaObject", "qt_metacast", "qt_metacall", "trUtf8", "qt_static_metacall"] + \
    [("void","QPixmap(char)"), ("bool","loadFromData(QByteArray,char,Qt::ImageConversionFlags)")] #qpixmap

#TODO doesnt handle collisions
#TODO HAXXX
class ModLUT1:
  basepath = ("Graphics", "UI", "Qtah", "Generator", "Interface")
  modlist = [x.strip().replace("./","").split("/") for x in open("./modlist.txt", "r").readlines()]
class ModLUT2:
  gen = lambda x,y : Import(path=ModLUT1.basepath + (x.lstrip("Qt"), y), imports=("c_%s" % y, ))
class ModLUT:
  modlut = {
      "c_%s" % b: ModLUT2.gen(a,b) for a,b in ModLUT1.modlist
      }
  def mkLookupImport(clstr):
    return ModLUT.modlut[clstr]

#todo consider tagging methods with features?
def callGen(classElem):
  clinf = ClassInfo(classInclude, classElem)
  __features = clinf.superclassFeatures
  features, methods, failures = Correlate.correlate(classElem, ignores=FilterRules.ignoreFns)
  _features, methods, failures = Convert.hoppyMethodsToStrings(methods)
  features = mergeFeatures([features, _features, __features])
  return Rules.genModule(clinf, features, methods)



if __name__ == "__main__":
  classInclude, className = App.parseArgs()
  tree = App.getXML(classInclude)
  classElem = App.getClassElem(tree)
  #TODO: logging
  App.dumpClassXML(classElem)
  #Rules(className).
  #print(result)
