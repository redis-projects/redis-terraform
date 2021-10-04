echo *****************MIXED**********************
(cd ../ && PYTHONPATH=. name=deji-test config=config.yaml.mixed terraformpy)
(cd ../ && json_diff f main.tf.json tests/main.tf.json.mixed)
echo *****************AWS**********************
(cd ../ && PYTHONPATH=. name=deji-test config=config.yaml.aws terraformpy)
(cd ../ && json_diff f main.tf.json tests/main.tf.json.aws)
echo *****************GCP**********************
(cd ../ && PYTHONPATH=. name=deji-test config=config.yaml.gcp terraformpy)
(cd ../ && json_diff f main.tf.json tests/main.tf.json.gcp)
