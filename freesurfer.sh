cat list.txt | parallel --jobs 40 recon-all -subjid {.} -i /home/crc_neuromod/BIDS/{.}/ses-10/anat/*run-01_T1w.nii.gz -all
