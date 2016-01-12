# Require jq > 1.4
# Takes open.fda.gov drug event JSON and transforms into compact flat linear records suitable for Perl recs-tocsv

# start from the .results array
.results




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
                         .key != "reportduplicate")) + 
       (.primarysource//{patientsource:{"NA":"NA"}}|with_entries(.key = "primarysource_" + .key)) + 
       (.sender//{sender:{"NA":"NA"}}|with_entries(.key = "sender_" + .key)) + 
       (.receiver//{receiver:{"NA":"NA"}}|with_entries(.key = "receiver_" + .key)) + 
       (.patient_summary//{patient_summary:{"NA":"NA"}}|with_entries(.key = "patient_summary_" + .key)) + 
       (.report_duplicate//{report_duplicate:{"NA":"NA"}}|with_entries(.key = "report_duplicate_" + .key)))

|map(del(.primarysource_primary_source))
|map(del(.sender_sender))
|map(del(.receiver_receiver))
|map(del(.report_duplicate_report_duplicate))
|map(del(.patient_summary_patient_summary))


#Iterates through array of objects to return a stream of objects instead of a single array
|.[]
