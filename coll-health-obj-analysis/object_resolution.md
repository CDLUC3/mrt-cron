[Object Health Home](README.md)

---

# Object Health Resolution

_This page is under construction_

## Invalid Mime Type

Could this be resolved just by changing the storage manifest?

Where does the mime type exist?

A mime type change on its own may not be sufficient to trigger a new version

Sample issues
- .iiq with tiff mime type.  Is tiff the wrapper?
- xml file names "mets.txt"
- rtf files with .doc extension
  - jhove reports as text file
  - droid reports as rtf
  - chrome downloads as rtf
- multipart/appledouble with jpg ext
  - jhove reports octet stream
  - droid reports appledouble

## Invalid file path

Requires a new version: delete + add

