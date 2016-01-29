#!/bin/bash
# Run in main faers2csv folder with jq v1.4

parallel --eta 'unzip -p {}|tee >(jq -S -r -f rxnfilter.jq |csvformat -B > csv/{/.}.reaction.csv) \
>(jq -S -r -f patientfilter.jq |csvformat -B > csv/{/.}.patient.csv) | jq -S -c -f drugfilter.jq |\
recs-annotate -k !^openfda! -MDigest::MD5=md5_hex \
    '\''{{openfda_md5}} = md5_hex(join(";", sort @{$r->get_group_values("!^openfda!", 1)}))'\'' \
  |tee >(recs-collate -k !^openfda! -a count |recs-tocsv|csvformat -B > csv/{/.}.openfda.csv) \
  |recs-tocsv -k receiptdate,\
  safetyreportid,\
  actiondrug,\
  activesubstancename,\
  medicinalproduct,\
  openfda_md5,\
  openfda_brand_name,\
  openfda_generic_name,\
  drugadditional,\
  drugcumulativedosagenumb,\
  drugcumulativedosageunit,\
  drugdosageform,\
  drugintervaldosagedefinition,\
  drugintervaldosageunitnumb,\
  drugrecurreadministration,\
  drugseparatedosagenumb,\
  drugstructuredosagenumb,\
  drugstructuredosageunit,\
  drugadministrationroute,\
  drugauthorizationnumb,\
  drugbatchnumb,\
  drugcharacterization,\
  drugdosagetext,\
  drugenddate,\
  drugenddateformat,\
  drugindication,\
  drugstartdate,\
  drugstartdateformat,\
  drugtreatmentduration,\
  drugtreatmentdurationunit |csvformat -B > csv/{/.}.drug.csv' ::: downloads/*.json.zip

parallel --eta 'csvstat {} > stats/{/.}.report.txt' ::: csv/*.csv

tar cf faerscsv.tar.bz2 --use-compress-prog=pbzip2 csv/
tar cf faerstats.tar.bz2 --use-compress-prog=pbzip2 stats/

parallel --eta '../Dropbox-Uploader/dropbox_uploader.sh upload {} csv6' ::: *.bz2
