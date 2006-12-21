" various useful abbreviations
abbr TMP [% %]<Esc>2hi
abbr TD <td></td><Esc>4hi
abbr TR <tr></tr><Esc>4hi
abbr TABLE <table><Enter></table><Esc>7hi
abbr FORM <form><Enter></form><Esc>6hi

" this is a macro that is invoked with s.  What it is supposed to do is to take
" an "argument" as one word on a line and then use that is a function name. It
" will create the function as well as a fold for the function and a pod
" template.  Killer.
let @s="0\"xdwi#{{{\"xpAsub \"xpA {=head2 \"xpAfoo=cut# Code Goes Here}#}}}zao"

