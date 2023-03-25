#!/bin/bash
#--------------------------------------------------------------------------#

Usage() {
cat <<EOF

Version edited on 24.03.2023

This script has been developed by Srinivas Balachander and Rujuta Parlikar for the Clinical Research Centre for Neuromodulaiton in Psychiatry

All folders within your DICOM directory should be names as per the project's convention, e.g, 10DEPCRC31001

The following argument is needed:

Bids_CRC.sh --dicom <path/to/dicom>

The following arguments are optional:

--bids <path/to/bids>: If this is not provided, the default is BIDS

--subj: The DICOM folder name of the subject/session that you want to specifically convert. If this is not specified, then this is attempt to convert all subjects within the DICOM directory for whom conversion has not yet been done.

--ncores: Number of parallel cores to use for conversion (Default: 8)

EOF
exit 1
}

[ _$1 = _ ] && Usage

# Parsing arguments from the command line

while [ _$1 != _ ]; do
case "$1" in
--dicom)
 DICOMDIR=$2
 shift
 ;;
  --bids)
 BIDSDIR=$2
 shift
 ;;
--subj)
 SUBJS=$2
 shift
 ;;
--ncores)
 NCORES=$2
 shift
 ;;
 *)
 echo "Unknown argument: $1";;
esac
shift
done

# Input check

if [ -z ${BIDSDIR} ]; then
mkdir -p BIDS
BIDSDIR=BIDS
fi

if [ -z ${NCORES} ]; then
NCORES=8
fi


echo "The Dicom directory is ${DICOMDIR}"
echo " "
echo "The BIDS directory is ${BIDSDIR}"
echo " "
echo "The number of cores that will be used is ${NCORES}"
echo " "

for i in `basename -a ${DICOMDIR}/*`; do

# Get the subject and session ID from the filename

SES=${i:0:2}
SUBID=${i:2:11}

if [ -d "${BIDSDIR}/sub-${SUBID}/ses-${SES}" ]; then
 echo "BIDS conversion for sub-${SUBID} and ses-${SES} is already done, moving on to the next.."
 echo " "
 else
  echo  "Starting Nifti conversion for ${i}"
  echo " "
# NIFTI Conversion
mkdir -p nifti/${i}

dcm2niix -b y -ba n -z y -f '%f_%p' -o nifti/${i} ${DICOMDIR}/${i}

echo "${i} is converted to Nifti"
echo "BIDS transformation for ses-$SES of sub-$SUBID has begun!"
echo "........"

cd nifti/$i

# Rename all the files properly
rename "s/$i/sub-${SUBID}_ses-${SES}/" *

rename "s/T1w_PSIR/PSIR/" *

rename "s/fieldmap_e1_ph/phase1/" *
rename "s/fieldmap_e2_ph/phase2/" *
rename "s/fieldmap_e1/magnitude1/" *
rename "s/fieldmap_e2/magnitude2/" *

rename "s/AP/dir-AP_epi/" *
rename "s/PA/dir-PA_epi/" *

rename "s/Ref_rest/acq-rest/" *
rename "s/Ref_DWI/acq-dwi/" *

rename "s/DKI/acq-80dir_dwi/" *
rename "s/DTI_6dir/acq-06dir_dwi/" *

# Add required lines to various json files

find *task-rest_bold*.json -exec \
sed -i '/"PhaseEncodingAxis": "j",/a\\t"PhaseEncodingDirection": "j",' {} \;

find *dir-AP_epi*.json -exec \
sed -i 's/"PhaseEncodingAxis": "j",/&\n\t"PhaseEncodingDirection": "j-",/' {} \;

find *dir-PA_epi*.json -exec \
sed -i 's/"PhaseEncodingAxis": "j",/&\n\t"PhaseEncodingDirection": "j",/' {} \;

# Make subdirectories
mkdir ses-${SES}
mkdir ses-${SES}/anat
mkdir ses-${SES}/func
mkdir ses-${SES}/fmap
mkdir ses-${SES}/dwi
mkdir ses-${SES}/survey

# Move all the files to the proper sub-directories
mv *Survey* ses-${SES}/survey/

mv *T1w* ses-${SES}/anat/
mv *T2W_TSE* ses-${SES}/anat/
mv *T2w* ses-${SES}/anat/
mv *FLAIR* ses-${SES}/anat/
mv *PSIR* ses-${SES}/anat/

mv *_dir-* ses-${SES}/fmap/
mv *magnitude* ses-${SES}/fmap/
mv *phase* ses-${SES}/fmap/

mv *task-rest* ses-${SES}/func/

mv *06dir_dwi* ses-${SES}/dwi/
mv *80dir_dwi* ses-${SES}/dwi/
mv *dwi* ses-${SES}/dwi/

cd ../../

# Make a new BIDS directory
mkdir -p ${BIDSDIR}/sub-${SUBID}

# Move all the files to the BIDS directory
mv nifti/${i}/ses-${SES} ${BIDSDIR}/sub-${SUBID}/

echo "BIDS transformation for  ses-$SES of sub-$SUBID is complete!"

# Remove the nifit sub-directory if its empty

if [ -z "$(ls -A nifti/${i})" ]; then
 rm -r nifti/${i}
else
 echo "There may be some files within the Nifti directory that were not converted to BIDS - check them !!!"
fi

echo "......"
fi;

done
