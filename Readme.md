faers2csv
======
This is a set of scripts I wrote to process the drug event data download files provided by the [US FDA's open.fda.gov API](https://open.fda.gov/update/openfda-now-allows-direct-downloads-of-data/) from large JSON files into much smaller relational CSV files.

I would not recommend running these scripts on a desktop computer. Processing all 95 JSON files into 380 CSV files takes 4-5 hours on a [Digital Ocean](https://www.digitalocean.com/pricing/) virtual server with 16 cores and 48 GB RAM. The scripts use [GNU Parallel](http://www.gnu.org/software/parallel/) to process the data on all available cores in a series of pipelines. You will be downloading approximately 10 GB zipped JSON that expand to about 100 GB and this compresses down to about 800 MB as a bzipped tar ball that expands to about 6 GB in total.

## FAERS JSON
The download files are zipped JSON, broken into quarters, and seem to be capped at about 80K reports per file. Teh general structure of each report is [here](https://open.fda.gov/drug/event/#adverse-event-reports), and the detailed field-by-field reference is [here](https://open.fda.gov/drug/event/reference/#field-by-field-reference). My scripts break down each report into:

1. A **patient** table with header and patient demographic data
2. A **reaction** table with information on each reaction, linked back to the patient with a unique idnetifier
3. A **drug** table with information on each drug, linked back to the patient with a unique identifier
4. An **openfda** table with information on the *openfda* object, when present, linked back to each drug with an `md5_sum` of the object itself.

## The Pipeline

### Unzip
The zipped JSON files are unzipped in place as a stream with `unzip -p` to save space and then piped into the next stage.

### Parse JSON, Extract and Flatten, save to file as CSV
The FAERS JSON files are pretty printed, which makes them easy to read (the first hundred or so) but stream processing difficult. I use [jq](https://stedolan.github.io/jq/) to parse the JSON, extract the fields and objects of interest, flatten nested structures, and output CSV. For the **patient** and **reaction** files, we're done here. We write an intermediate **drug** file here that will need to be split into **drug** and **openfda** files in the next step. The `jq` filter for drugs concatenates all the arrays in the openfda object into ; delimited strings (I will probably need to sort before joining as well, but I haven't yet and nothing too teribble happens). The size and redundancy of the openfda objects are the main reason the JSON files are so incredibly big. 

This last point of course makes sense if you think for a minute that there are hundreds of millions of Americans who could potentially use prescription drugs, but there aren't hundreds of millions of unique drugs, in fact it looks like there are no more than maybe 20K unique representations for drug in this data and there is likely to be a fair amount of rendundancy even there. 

### Record Stream to calculate `md5_sum` for each openfda object, split into **drug** and **openfda** tables and collate **openfda**.
This step is non-trivial an dI couldn't figure out how to do it in `jq`, so I used perl's [RecordStream](https://github.com/benbernard/RecordStream) to read in the intermediate drug CSV file from the last step, sort the openfda fields, concatenate with ; and finally calculate an `md5_sum` as a new field. Then we split into the **drug** CSV and the **openfda** and then deduplicate the **openfda** table by counting each (useful as a checksum later).

### Backup intermediate files, calculate stats, and bzip before transfer.
I don't delete the intermediate **drug** CSVs just yet, but instead move them to a backup folder, in case something went wrong. Then I use the `csvstat` from Python's [csvkit](https://csvkit.readthedocs.org/en/0.9.1/) to generate reports on all of the individual CSV files (there should be 380 of them from 95 zipped JSONs) to make sure they all have the right number of columns, and that no records got lost (this is how I found out that the `safetyreportid` is not in fact unique). 

### Zip and transfer
Assuming you're running these scripts on a multi-core processor, [pbzip2](http://compression.ca/pbzip2/) lets you use them all to improve the speed of `bzip`. I use [Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader) to dump everything at the end so I can destroy the droplet as soon as posisble. 

## The Files

* **fdadl**: This is a script to download the zipped JSON from [open.fda.gov](http://open.fda.gov)
* **patientfilter.jq**: This is the `jq` script to produce the patient CSV.
* **rxnfilter.jq**: This is the `jq` script to produce the reaction CSV.
* **drugfilter.jq**: This is the `jq` script to product the intermediate drugfilter CSV.
* **faers2csv.sh**: This is the bash script that uses `parallel` to call everythign else. 
..* Make sure you've got a `downloads` folder with the zipped JSONs, empty `csv`, `drugbackup`, and `stats` folders, and the `jq` filters in the same dir you run this script from.
* **scratchpad**: This is my scratch space. ignore it. or don't.
