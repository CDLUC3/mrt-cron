## TODO
- Database
  - detect file delete
  - track dates
    - build_datetime
      - rebuild if inv_objects.modified > object_health_json.build_dateime || config.build_datetime > object_health_json.build_dateime
    - analysis_datetime
      - re-run if object_health_json.build_dateime > object_health_json.analysis_dateime || config.analysis_datetime > object_health_json.analysis_dateime
    - test_datetime
      - re-run if object_health_json.build_dateime > object_health_json.analysis_dateime || config.test_datetime > object_health_json.analysis_dateime
