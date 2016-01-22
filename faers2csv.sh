#!/bin/bash
# Run in main faers2csv folder with jq v1.4

parallel --eta 'unzip -p {1}| jq -s -r -f {2} > csv/{1/.}.{2/.}.csv' ::: downloads/*.json.zip ::: *.jq

parallel --eta 'recs-fromcsv --header {} | \
  recs-annotate -k !^openfda! -MDigest::MD5=md5_hex \
    '\''{{openfda_md5}} = md5_hex(join(";", sort @{$r->get_group_values("!^openfda!", 1)}))'\'' \
  |tee >(recs-collate -k !^openfda! -a count |recs-tocsv > csv/{/.}.openfda.csv) \
  |recs-tocsv -k safetyreportid,actiondrug,activesubstancename,medicinalproduct,openfda_md5,openfda_brand_name,openfda_generic_name,!drug! > csv/{/.}.drug.csv); \
  mv {} drugbackup/{/}' ::: csv/*.drugfilter.csv

parallel --eta 'csvstat {} stats/{/.}.report.txt' ::: csv/*.csv
       
parallel --eta '../Dropbox-Uploader/dropbox_uploader.sh upload {} csv3' ::: csv/*.csv
 
