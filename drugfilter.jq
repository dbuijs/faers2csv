# Require jq > 1.4
# Takes open.fda.gov drug event JSON and transforms into compact flat linear records suitable for Perl recs-tocsv
.[]
#start from the .results array
|.results


#Creates new object with .safetyreportid string and .patient.drug array
|map(with_entries(select(.key == "safetyreportid", .key == "receiptdate")) + (.patient.drug[]))

# Flattens .openfda and turns openfda arrays into strings delimited with ;
|map(with_entries(select(.key != "openfda")) + (.openfda//{openfda:{"NA":"NA"}}|with_entries(.value = ([.value[]|tostring]|sort|join(";")) |.key |= "openfda_"  + .)))

#Flattens .activesubstance array
|map(with_entries(select(.key != "activesubstance")) + (.activesubstance))

#Grabs all keys, and builds CSV, to fix jagged array
|["receiptdate",
"safetyreportid",
"actiondrug",
"activesubstancename",
"drugadditional",
"drugadministrationroute",
"drugauthorizationnumb",
"drugbatchnumb",
"drugcharacterization",
"drugcumulativedosagenumb",
"drugcumulativedosageunit",
"drugdosageform",
"drugdosagetext",
"drugenddate",
"drugenddateformat",
"drugindication",
"drugintervaldosagedefinition",
"drugintervaldosageunitnumb",
"drugrecurreadministration",
"drugseparatedosagenumb",
"drugstartdate",
"drugstartdateformat",
"drugstructuredosagenumb",
"drugstructuredosageunit",
"drugtreatmentduration",
"drugtreatmentdurationunit",
"medicinalproduct",
"openfda_application_number",
"openfda_brand_name",
"openfda_generic_name",
"openfda_manufacturer_name",
"openfda_nui",
"openfda_package_ndc",
"openfda_pharm_class_cs",
"openfda_pharm_class_epc",
"openfda_pharm_class_moa",
"openfda_pharm_class_pe",
"openfda_product_ndc",
"openfda_product_type",
"openfda_route",
"openfda_rxcui",
"openfda_spl_id",
"openfda_spl_set_id",
"openfda_substance_name",
"openfda_unii"] as $keys
|$keys, (.[]|[.[$keys[]]])|@csv

