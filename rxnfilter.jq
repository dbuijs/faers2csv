# Require jq > 1.4
# Takes open.fda.gov drug event JSON and transforms into compact flat linear records suitable for Perl recs-tocsv

#start from the .results array
.results



#Creates new object with .safetyreportid string and .patient.reaction array
|map(with_entries(select(.key == "safetyreportid", .key == "receiptdate")) + (.patient.reaction[]))

# Grabs all unique keys and spits out CSV
|["receiptdate","safetyreportid","reactionmeddrapt","reactionmeddraversionpt","reactionoutcome"] as $keys
|$keys, (.[]|[.[$keys[]]])|@csv
