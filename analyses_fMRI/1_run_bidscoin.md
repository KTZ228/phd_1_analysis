# Run BIDScoin
### Navigate to the project folder
`cd /project/3025011.02/`

### Activate environment
`module add bidscoin/4.5.0`

### Separate dicoms into folders
`dicomsort raw -i sub- -j ses-`

### Extract participant info from a dicom
You select which dicom by changing the wildcard
`rawmapper raw -f EchoTime PatientSex AcquisitionDate -w *06*`

### Run BIDSmapper
This is used to rename all your output
Make the fieldmap scans more user friendly, e.g. by naming the acquisition label simply acq-2p4iso and acq-2p5iso, and add a search pattern to the IntendedFor field such that the first field map will select your Reward runs and the second field map your Stop runs (see the bidseditor field map notes for more details)
`bidsmapper raw bids`

### Run BIDScoin
You can rerun this every time to apply your template to the data
`bidscoiner raw bids`

### BIDS validation
`module load bids-validator`

`bids-validator /project/3025011.02/bids`
`bids-validator /project/3025011.02/bids --verbose`

## Notes
Ensure that the PETRA, acq-a and ce-ND data are in the `extra_data` folder, otherwise, MRIQC or fMRIprep can accidentally use them instead of the normal T1w and T2w files.
The `acq-a` files are formed when an fMRI sequence is interupted prematurely. These are made up from the last `.IMA` files in the raw folder.