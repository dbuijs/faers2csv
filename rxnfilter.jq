# Require jq > 1.4
# Takes open.fda.gov drug event JSON and transforms into compact flat linear records suitable for Perl recs-tocsv

#start from the .results array
.results



#Creates new object with .safetyreportid string and .patient.reaction array
|map(with_entries(select(.key == "safetyreportid")) + (.patient.reaction[]))

#Iterates through array of objects to return a stream of objects instead of a single array
|.[]
