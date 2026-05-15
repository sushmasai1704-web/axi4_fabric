set nfacs [ gtkwave::getNumFacs ]
gtkwave::addRecentFile [gtkwave::getDumpFileName]
set all_facs [list]
for {set i 0} {$i < $nfacs} {incr i} {
    lappend all_facs [gtkwave::getFacName $i]
}
gtkwave::addSignalsFromList $all_facs
gtkwave::zoom_full
gtkwave::hardcopy ~/axi4_fabric/docs/waveform.png png
exit
