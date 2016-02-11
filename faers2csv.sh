#!/bin/bash
# Run in main faers2csv folder with jq v1.4
# Limit jobs to just under half of available processors to minimize swap time

parallel -j 8 --eta 'unzip -p {}|tee >(jq -r -f rxnfilter.jq |csvformat -B > csv/{/.}.reaction.csv) \
>(jq -r -f patientfilter.jq |csvformat -B > csv/{/.}.patient.csv) | jq -c -f drugfilter.jq |\
recs-annotate -k !^openfda! -MDigest::MD5=md5_hex \
    '\''{{openfda_md5}} = md5_hex(join(";", sort @{$r->get_group_values("!^openfda!", 1)}))'\'' \
  |tee >(recs-collate -k !^openfda! -a count \
  |recs-tocsv -k openfda_md5,\
  count,\
openfda_brand_name,\
openfda_generic_name,\
openfda_application_number,\
openfda_dosage_form,\
openfda_manufacturer_name,\
openfda_is_original_packager,\
openfda_product_ndc,\
openfda_nui,\
openfda_package_ndc,\
openfda_product_type,\
openfda_route,\
openfda_substance_name,\
openfda_spl_id,\
openfda_spl_set_id,\
openfda_pharm_class_epc,\
openfda_pharm_class_moa,\
openfda_pharm_class_cs,\
openfda_pharm_class_pe,\
openfda_upc,\
openfda_unii,\
openfda_rxcui |csvformat -B > csv/{/.}.openfda.csv) \
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

parallel --eta '../Dropbox-Uploader/dropbox_uploader.sh upload {} csv7' ::: *.bz2
