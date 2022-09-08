#!/bin/bash
#-----------------------------------------------------------------------
# ncfs_post_min.sh : Post processing for North Carolina.
#-----------------------------------------------------------------------
# Copyright(C) 2011--2017 Jason Fleming
#
# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ASGS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------
#
THIS=ncfs_post_to_current.sh

#
declare -A properties
SCENARIODIR=$PWD
RUNPROPERTIES=$SCENARIODIR/run.properties
if [[ $# -eq 1 ]]; then
   RUNPROPERTIES=$1
   SCENARIODIR=`dirname $RUNPROPERTIES`
fi

# get loadProperties function
SCRIPTDIR=`sed -n 's/[ ^]*$//;s/path.scriptdir\s*:\s*//p' $RUNPROPERTIES`
source $SCRIPTDIR/properties.sh

# load run.properties file into associative array
loadProperties $RUNPROPERTIES
CONFIG=${properties['config.file']}
CYCLEDIR=${properties['path.advisdir']}
CYCLE=${properties['advisory']}
HPCENV=${properties['hpc.hpcenv']}
HPCENVSHORT=${properties['hpc.hpcenvshort']}
SCENARIO=${properties['scenario']}
#HSTIME=${properties['InitialHotStartTime']}
SYSLOG=${properties['monitoring.logging.file.syslog']}
#CYCLELOG=${properties['monitoring.logging.file.cyclelog']}
#SCENARIOLOG=${properties['monitoring.logging.file.scenariolog']}
source $SCRIPTDIR/monitoring/logging.sh
source $SCRIPTDIR/platforms.sh

SCENARIODIR=${CYCLEDIR}/${SCENARIO}       # shorthand
cd ${SCENARIODIR} > errmsg 2>&1 || warn "cycle $CYCLE: $SCENARIO: $THIS: Failed to change directory to '$SCENARIODIR': `cat errmsg`."

ASGSADMIN=${properties["notification.email.asgsadmin"]}
GRIDNAME=${properties["adcirc.gridname"]}
INSTANCENAME=${properties["instancename"]}
HPCENVSHORT=${properties["hpc.hpcenvshort"]}
TROPICALCYCLONE=${properties["forcing.tropicalcyclone"]}
BACKGROUNDMET=${properties["forcing.backgroundmet"]}
DOWNLOADURL=${properties["downloadurl"]}
WINDMODEL=${properties["forcing.nwp.model"]}

#--------------------------------------------------------------------------
#        N C F S   _   C U R R E N T   P U B L I C A T I O N
#--------------------------------------------------------------------------
#
# construct the opendap directory path where the results will be posted
#
currentDir=NCFS_CURRENT_DAILY
#if [[ $TROPICALCYCLONE = on ]]; then
#   currentDir=NCFS_CURRENT_TROPICAL
#fi
localtdspath="/projects/ncfs/opendap/data/"

# Make symbolic links to a single location on the opendap server
# to reflect the "latest" results. There are actually two locations, one for 
# daily results, and one for tropical cyclone results. 
currentResultsPath="$localtdspath/$currentDir"
echo "currentResultsPath=+$currentResultsPath+"  # BOB

if [ ! -d "$currentResultsPath" ] ; then
   echo "mkdir-ing $currentResultsPath"
   mkdir -p $currentResultsPath
fi
cd $currentResultsPath 2>> ${SYSLOG}

# get rid of the old stuff
rm -rf * 2>> ${SYSLOG}

# copy files 
#for file in $SCENARIODIR/fort.*.nc $SCENARIODIR/swan*.nc $SCENARIODIR/max*.nc $SCENARIODIR/min*.nc $SCENARIODIR/run.properties $SCENARIODIR/fort.14 $SCENARIODIR/fort.15 $SCENARIODIR/fort.13 $SCENARIODIR/fort.22 $SCENARIODIR/fort.26 $SCENARIODIR/fort.221 $SCENARIODIR/fort.222 $ADVISDIR/al*.fst $ADVISDIR/bal*.dat $SCENARIODIR/*.zip $SCENARIODIR/*.kmz ; do 
for file in $SCENARIODIR/fort.*.nc $SCENARIODIR/swan*.nc $SCENARIODIR/max*.nc $SCENARIODIR/min*.nc $SCENARIODIR/run.properties $SCENARIODIR/fort.15  $SCENARIODIR/fort.22 $SCENARIODIR/fort.26 ; do 
   if [ -e $file ]; then
      cp $file . 2>> ${SYSLOG}
   else
      logMessage "$SCENARIO: $THIS: The directory does not have ${file}."
   fi
done

# Copy the latest run.properties file to a consistent location in opendap
#cp run.properties $localtdspath/run.properties.${HPCENVSHORT}.${INSTANCENAME} 2>> ${SYSLOG}
cp run.properties.json $localtdspath/run.properties.json 2>> ${SYSLOG}
cp run.properties $localtdspath/run.properties 2>> ${SYSLOG}
d=`date --utc +"%Y-%h-%dT%H-%M-%S%Z"`
echo $d > update.time
touch "Posted_at_"$d

touch "DateCycle_"$CYCLE"Z"
touch "ADCIRCgrid_"$GRIDNAME
touch "Scenario_"$SCENARIO
str=$WINDMODEL"_"$CYCLE"_"$SCENARIO"_"$GRIDNAME
touch $str 

echo "updatetime : $d" > meta.json
echo "advisory : NA" >> meta.json
echo "datecycle : $CYCLE""Z" >> meta.json
echo "stormname : synoptic" >> meta.json
echo "stormnumber : NA" >> meta.json
echo "scenario : $SCENARIO" >> meta.json
echo "asgsadmin : $ASGSADMIN" >> meta.json
echo "gridname : $GRIDNAME" >> meta.json
echo "instancename : $INSTANCENAME" >> meta.json
echo "hpcenv : $HPCENVSHORT" >> meta.json
echo "windmodel : $WINDMODEL" >> meta.json
echo "backgroundmet : $BACKGROUNDMET" >> meta.json
echo "downloadurl : $DOWNLOADURL" >> meta.json

# switch back to the directory where the results were produced 
cd $SCENARIODIR 2>> ${SYSLOG}

