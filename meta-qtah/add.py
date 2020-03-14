#! /usr/bin/env nix-shell
#! nix-shell -p python37 -i python3

#TODO write stderr (i.e. failures) to generated.fail file or something

#TODO this is really bad
#I wanted to use diff patches with context originally but it didnt work how I wanted
import sys
import shutil
import tempfile

plus = False
try:
  plus = sys.argv[2] == "+"
except:
  pass

classModule, className = sys.argv[1].split("/") #TOOD system path sep i guess?
hsClassName, hsClassModule = "c_%s" % className, classModule.lstrip("Qt")

entries = [
  ("qtah-generator/qtah-generator.cabal",
    "    , Graphics.UI.Qtah.Generator.Interface.Core.QAbstractAnimation",
    "    , Graphics.UI.Qtah.Generator.Interface.{hsClassModule}.{className}"
    ),
  ("qtah-generator/src/Graphics/UI/Qtah/Generator/Interface/{hsClassModule}.hs",
    "import qualified Graphics.UI.Qtah.Generator.Interface.{hsClassModule}.",
    "import qualified Graphics.UI.Qtah.Generator.Interface.{hsClassModule}.{className} as {className}"
    ),
  ("qtah-generator/src/Graphics/UI/Qtah/Generator/Interface/{hsClassModule}.hs",
    ".aModule",
    "    , {className}.aModule"
    ),
  ("qtah/qtah.cabal",
    "    , Graphics.UI.Qtah.Core.QAbstractAnimation",
    "    , Graphics.UI.Qtah.{hsClassModule}.{className}"
    ),
  ("qtah/qtah.cabal",
    "  other-modules:",
    "      Graphics.UI.Qtah.Generated.{hsClassModule}.{className}"
    )
  ] if plus else []

args = { "hsClassName" : hsClassName, "className" : className, "hsClassModule" : hsClassModule}
def addOnceToFile(path, match, add):

  match = match.format(**args)
  add = add.format(**args)
  path = path.format(**args)

  print('trying to add "%s" after "%s" in "%s"' % (add, match, path))

  def matcher(match, x):
    if x.strip().endswith(match.strip()) or x.strip().startswith(match.strip()):
      print("added")
      return (x,add + "\n")
    else:
      return (x,)

  with tempfile.NamedTemporaryFile("a", delete=False) as f:
    f.seek(0)
    lines = open(path, "r").readlines()
    results = []
    flag = True
    for x in lines:
      if flag:
        _result = matcher(match, x)
        if len(_result) == 2:
          flag = False
      else:
        _result = (x,)
      results += [_result]

    f.writelines(sum(results, ()))
    f.flush()
    shutil.move(f.name, path)

def callGen():
  import subprocess
  import os
  import textwrap
  mypath = os.path.dirname(os.path.abspath(__file__))

  target = "qtah-generator/src/Graphics/UI/Qtah/Generator/Interface/{hsClassModule}/{className}.hs"
  target = target.format(**args)

  cmd = ["%s/gen.py" % mypath] + sys.argv[1:]
  try:
    hdl = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE )
    out, err = hdl.communicate()
    if hdl.returncode != 0:
      raise subprocess.CalledProcessError(hdl.returncode, cmd, err)
    print("subprocess stderror:\n" + textwrap.indent(err.decode("ascii"), "    "), file=sys.stderr)
  except subprocess.CalledProcessError as e:
    print("subprocess error:\n" + textwrap.indent(e.output.decode("ascii"), "    "), file=sys.stderr)
    raise e

  with open(target, "x") as f:
      f.write(out.decode("utf-8"))
  with open(target + ".fail", "w") as f: #opened as w because if it exists we should fail on the other open, otherwise we should overwrite with new data
    print("subprocess stderror:\n" + textwrap.indent(err.decode("ascii"), "    "), file=f)


callGen() #TODO fail if fail
for x in entries:
  addOnceToFile(*x)

print("done")
