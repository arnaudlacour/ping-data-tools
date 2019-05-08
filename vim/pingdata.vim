" Vim syntax file
" Language:         PingData log files
" Maintainer:       Arnaud Lacour <arno@pingidentity.com>


if exists("b:current_syntax")
  finish
endif

syntax keyword operationType ABANDON ADD BIND CONNECT DELETE DISCONNECT EXTENDED MODIFY MODDN SECURITY SEARCH 
highlight link operationType Keyword

syntax match pingError 	        'resultCode=[^0]\d*'
highlight link pingError     ErrorMsg

syntax region purpose start=/administrativeOperation="/hs=s+25 end=/"/he=e-1
syntax region purpose start=/opPurpose="/hs=s+11 end=/"/he=e-1
highlight link purpose Comment

syntax region DN start=/requesterDN="/hs=s+13 end=/"/he=e-1
syntax region DN start=/authDN="/hs=s+8 end=/"/he=e-1
syntax region DN start=/base="/hs=s+6 end=/"/he=e-1
syntax region DN start=/dn="/hs=s+4 end=/"/he=e-1
highlight DN cterm=bold

syntax region resultCodeName start=/resultCodeName="/hs=s+16  end=/"/he=e-1
highlight resultCodeName cterm=standout

syntax region logString 	    start=/'/hs=s+1 end=/'/he=e-1 end=/$/ skip=/\\./  
syntax region logString 	    start=/"/hs=s+1 end=/"/he=e-1 end=/$/ skip=/\\./
highlight link logString String

syntax match logNumber 	    /=\d\d*\.\=\d* /hs=s+1,he=e-1
highlight link logNumber Number

syntax region logDate start=/^\[/hs=s+1 end=/:/he=e-1
highlight link logDate Type

syntax match logTime    '\d\d:\d\d:\d\d\.\d\d\d'
highlight link logTime  Type

syntax match logTZ  ' .\d\d\d\d'
highlight link logTZ Label

let b:current_syntax = "pingdata"