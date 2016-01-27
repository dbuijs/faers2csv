# Require jq > 1.4
# Takes open.fda.gov drug event JSON and transforms into compact flat linear records suitable for Perl recs-tocsv

# start from the .results array
|.results




# remove .patient.drug array
|map(del(.patient.drug))

# remove .patient.reaction array
|map(del(.patient.reaction))

# flattens .patient object and renames child keys with patient_ prefix
|map(with_entries(select(.key != "patient")) + 
       (.patient|with_entries(.key = "patient_" + .key)))

# flattens all the objects and renames child keys
|map(with_entries(select(.key != "primarysource" and 
                         .key != "sender" and 
                         .key != "receiver" and 
                         .key != "patient_summary" and 
                         .key != "reportduplicate" and
                         .key != "patient_patientdeath")) + 
       (.primarysource//{primarysource:{"NA":"NA"}}|with_entries(.key = "primarysource_" + .key)) + 
       (.sender//{sender:{"NA":"NA"}}|with_entries(.key = "sender_" + .key)) + 
       (.receiver//{receiver:{"NA":"NA"}}|with_entries(.key = "receiver_" + .key)) + 
       (.patient_summary//{patient_summary:{"NA":"NA"}}|with_entries(.key = "patient_summary_" + .key)) + 
       (.report_duplicate//{report_duplicate:{"NA":"NA"}}|with_entries(.key = "report_duplicate_" + .key))+
       (.patient_patientdeath//{patient_patientdeath:{"NA":"NA"}}|with_entries(.key = "patient_patientdeath_" + .key)))

|map(del(.primarysource_primarysource))
|map(del(.sender_sender))
|map(del(.receiver_receiver))
|map(del(.report_duplicate_report_duplicate))
|map(del(.patient_summary_patient_summary))
|map(del(.patient_patientdeath_patient_patientdeath))

# grabs all unique keys and spits out CSV
|["safetyreportid",
"authoritynumb",
"companynumb",
"duplicate",
"fulfillexpeditecriteria",
"occurcountry",
"patient_patientagegroup",
"patient_patientonsetage",
"patient_patientonsetageunit",
"patient_patientsex",
"patient_patientweight",
"patient_summary_narrativeincludeclinical",
"primarysource_literaturereference",
"primarysource_qualification",
"primarysource_reportercountry",
"primarysourcecountry",
"receiptdate",
"receiptdateformat",
"receivedate",
"receivedateformat",
"receiver_receiverorganization",
"receiver_receivertype",
"reporttype",
"safetyreportversion",
"sender_senderorganization",
"sender_sendertype",
"serious",
"seriousnesscongenitalanomali",
"seriousnessdeath",
"seriousnessdisabling",
"seriousnesshospitalization",
"seriousnesslifethreatening",
"seriousnessother",
"transmissiondate",
"transmissiondateformat"] as $keys
|$keys, (.[]|[.[$keys[]]])|@csv

