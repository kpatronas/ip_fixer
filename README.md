# ip_fixer
ip_fixer is a tool that scans scans for IP addresses inside files and do changes in their octets

Parameters:
  Usage: ip_fixer old_octet new_octet [octet_position]
  old_octet: When this value found inside an IP address it will be changed with the value of new_octet
  new_octet: This valie will replace old_octet
  octet_position: When this value ommited changes will take plce in octets in range of 1-4, if given the changes will take place
  in the given range of octets or specific octet
  octet_position example values: 1:    It will do only matching changes in the first octet
                                 2-3:  It will do only matching changes in the rang of octets 2-3

Configuration: The script needs a configuration file in the same directory as the script (config.csv), this file is a list of filenames and/or directories, the script will do any changes in the files defined and also will do changes in ANY text file found inside the first level of the given directory

Backup: This script will generate backup files of each file that does a change, the backed up file will be in the same directory
with the .bck extension added

