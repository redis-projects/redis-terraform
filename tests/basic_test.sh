echo *****************MIXED**********************
(cd ../ && PYTHONPATH=. name=unit-test-name config=config.yaml.mixed terraformpy)
(cd ../ && json_diff tests/main.tf.json.mixed main.tf.json)
echo *****************AWS**********************
(cd ../ && PYTHONPATH=. name=unit-test-name config=config.yaml.aws terraformpy)
(cd ../ && json_diff tests/main.tf.json.aws main.tf.json)
echo *****************GCP**********************
(cd ../ && PYTHONPATH=. name=unit-test-name config=config.yaml.gcp terraformpy)
(cd ../ && json_diff tests/main.tf.json.gcp main.tf.json)
