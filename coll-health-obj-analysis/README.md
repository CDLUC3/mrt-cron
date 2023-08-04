# Collection Heath Object Analysis

## Object Analysis Schema

```yaml
object:
  id: 222
  identifiers:
    ark: "ark://12345/abcde"
    local-ids: ['aaa', 'bbb']
  container:
    collection: "mnemonic"
    owner: "ABCD"
  modified: "2023-01-01 11:22:33"
  metadata:
    who: "aaa"
    what: "bbb"
    when: "ccc"
  key-changes:
    versions-with-embargo: [1,2]
    versions-with-delete: [2]
  producer-files:
    versions:
      num: 1
      files: 
      - id: 234
        path: "bbb"
        billable_size: 123
        md5: "aaa"
        mime_type: "image/tiff"
        # I presume we would want to store these results in MySQL as well
        analyis-traits:
          # sustainable | at-risk | unsustainable | unknown
          format-sustainability: "sustainable"
          format-id-scan:
            result: "PASS"
            details: {}
            last-run: "2023-01-01 11:22:33"
          virus-scan:
            result: "FAIL"
            details: {}
            last-run: "2023-01-01 11:22:33"
          pii-scan-results:
            result: "PASS"
            details: {}
            last-run: "2023-01-01 11:22:33"
analysis-test-log:
- test-name: "cccc"
  # test-type
  #   file-metadata: tests that rely only on file metadata
  #   file-bitstream: tests that rely on scanning file bitstream content 
  #   object-metadata: tests that rely only on object metadata
  #   object-composition: tests that analyze the combination of files
  #   collection-consistency: tests based on collection expectation and collection configuration files
  test-type: "xxx"
  test-result: "WARN"
  result: "PASS"
  details: {}
  last-run: "2023-01-01 11:22:33"
  # each test will have an inherent expiration... when does it need to run again
  expiration: "..."

```
