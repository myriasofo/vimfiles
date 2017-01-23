" Custom commands for MBE - resize and display
    "fun! MBE_resize(...)
    "    if a:0 > 0
    "        let g:miniBufExplVSplit = a:1
    "    else
    "        let size = g:longestFilename + 5
    "        let DEFAULT = 20
    "        if size > DEFAULT
    "            let g:miniBufExplVSplit = size
    "        else
    "            let g:miniBufExplVSplit = DEFAULT
    "        endif
    "    endif
    "
    "    " Save prev location
    "    let winPrev = winnr()
    "
    "    " Refresh MBE
    "    MBEToggle
    "    MBEToggle
    "
    "    MBEFocus
    "    "set nornu
    "
    "    " Return to prev win
    "    exe winPrev.' wincmd w'
    "endfun

    fun! MBE_switch()
        " Save prev location
        MBEToggle
        "let winPrev = winnr()
        "
        "" If open, close
        "if bufname(winbufnr(1)) == '-MiniBufExplorer-'
        "    MBEClose
        "" If not opened, open then jump back to prev
        "else
        "    MBEOpen
        "    let winPrev += 1
        "    exe winPrev . ' wincmd w'
        "endif
    endfun

    command! MSwitch call MBE_switch()
    command! -nargs=? MResize call MBE_resize(<args>)
