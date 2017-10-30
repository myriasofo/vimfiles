" NOTE: This plugin maps a bunch of functionality to the 's' key
"       Since 's' is easy to press, I put my most impt maps here
" why use process key, instead of just mappings?

fun! ScoutKey()
    let char = ProcessChar()

    " Keys for right hand
    if char == 'y'
        " Open up vimrc
        if expand('%:t') != 'vimrc'
            if exists("g:dir_myPlugins")
                exe 'edit '.g:dir_myPlugins.'plugin/vimrc'
            else
                edit ~/vimrc
            endif
        endif
    elseif char == 'u'
        call ExecuteCurrentFile()
    elseif char == 'i'
        call Spacework_Dialog()
    elseif char == 'o'
        call NavKey_ListBookmarks()
    "elseif char == 'p'
        "edit .
        "call Spacework()
        "CtrlPBookmarkDirAdd
        "call RemoveBufList_fromCtrlp()
        "call Update_ctrlpCommand("")
        "CtrlPCurWD
        "call OpenFile_inWs()
        "CtrlPDir getcwd()
        "call NavKey()
        "CtrlPBookmarkDir


    elseif char == 'h'
        call LoadFile(g:dir_palettes . 'stable.to')
    elseif char == 'j'
        exe "normal! \<c-w>h"
        if &filetype == 'minibufexpl'
            exe "normal! \<c-w>l"
            echom "ERROR: Avoid navigating to mbe (bc of fugitive and Gstatus/Gcommit)"
        endif
        redraw!
    elseif char == 'k'
        exe "normal! \<c-w>k"
        redraw!
    elseif char == 'l'
        exe "normal! \<c-w>j"
        redraw!
    elseif char == ';'
        exe "normal! \<c-w>l"
        redraw!
    elseif char == ''''
        set hlsearch!


    elseif char == 'n'
        "call SetupWorkspace(g:dir_palettes.'list.to', g:dir_palettes.'temp1.to')
        call LoadFile(g:dir_palettes . 'flux.to')
    elseif char == 'm'
        call LoadFile(g:dir_palettes . 'list.to')
    elseif char == ','
        call LoadFile(g:dir_palettes . 'temp1.to')
    elseif char == '.'
        call LoadFile(g:dir_palettes . 'temp2.to')
    elseif char == '/'
        "call SetupWorkspace(g:dir_palettes.'temp1.to', g:dir_palettes.'temp2.to')
        call LoadFile(g:dir_notes . '_specials/timeLog.to')


    " Keys for left hand
    elseif char == 'e'
        call ClearOutHiddenBuffers()
    elseif char == 'r'
        set wrap!

    elseif char == 'a'
        let char = ProcessChar()
        call MagiOpenBuffer(char)
    elseif char == 's'
        redraw!
    elseif char == 'd'
        let char = ProcessChar()
        call MagiRemoveBuffer(char)
    elseif char == 'f'
        let char =ProcessChar()
        if char ==  'f'
            call cursor(line('$')/2, 0)
        elseif char == 'j'
            normal! ^
        elseif char == 'k'
            normal! gg
        elseif char == 'l'
            normal! G
        elseif char == ';'
            normal! $
        endif


    elseif char == 'z'
        call SwapWin_2and3()
    elseif char == 'x'
        normal! v
    elseif char == 'c'
        exe "normal! \<c-v>"
    elseif char == 'v'
        normal! V
    elseif char == 'b'
        let char = ProcessChar()
        if char == 'j'
            vs
        elseif char == 'k'
            split
        elseif char == 'l'
            belowright split
        elseif char == ';'
            belowright vsplit
        endif

        "call OnAddingWin() 
        "call HL_OrphanedWhitespace()


    " Keys for other
    elseif char == "\<esc>"
        echom 'ScoutKey: Cancelled'

    else
        echom 'ScoutKey: Nothing happened'
    endif
endfun


fun! SetupWorkspace(fileA, fileB)
    " Close all wins except 1 and 2
    let winPrev = winnr()
    if winnr('$') > 3
        for i in range(3, winnr('$'))
            exe i.' wincmd w'
            quit
        endfor
    endif

    " Then open up my two new files
    let bufname2 = expand('#'.winbufnr(2).':t')
    let bufname3 = expand('#'.winbufnr(3).':t')

    if bufname2 != fnamemodify(a:fileA,':t')
        exe '2 wincmd w'
        exe 'edit ' . a:fileA
    endif

    if bufname3 != fnamemodify(a:fileB,':t')
        if winbufnr(3) == -1
            belowright vsplit
        endif
        exe '3 wincmd w'
        exe 'edit ' . a:fileB
    endif

    " Return to prev win (as long as not gone)
    if winbufnr(winPrev) != -1
        exe winPrev . ' wincmd w'
    endif
endfun

fun! LoadFile(fullpath)
    if expand('%:p') != a:fullpath
        exe 'edit ' . a:fullpath
        if line('.') == line('$') && winline() == 1 " If cursor pos is awk, move down
            normal! zb
        endif
    endif
endfun

fun! SwapWin_2and3()
    " As written, only works for win2 and win3 (my usu setup)

    " Preserve starting win and cursor location
    let winPrev = winnr()
    normal! mC

    " If MBE, 2 and 3. If no MBE, then 1 and 2
    let winA = (IsMBEOpen() ? 2 : 1)
    let winB = (IsMBEOpen() ? 3 : 2)

    " Preserve buf# in win2 and win3
    let buf_fromWinA = winbufnr(winA)
    let buf_fromWinB = winbufnr(winB)

    " Print error if there isn't enough windows open to swap
    if buf_fromWinB == -1
        echom "ERROR: Not enough windows to swap"
        return
    endif

    " CORE BEHAVIOR - Move to win and open buf from opposite win
    exe winA.' wincmd w'
    exe buf_fromWinB.' buffer'

    exe winB.' wincmd w'
    exe buf_fromWinA.' buffer'

    " Go back to orig buf (ie. swapped win)
    if winPrev == winA
        " stay at winB (bc cmd in prev section will you there)
    else
        exe winA.' wincmd w'
    endif

    " Go back to orig location
    normal! `C

    " Open all folds until the line is visible
    while !IsVisible(line('.'))
        normal! zo
    endwhile
endfun

fun! RemoveBufList_fromCtrlp()
    " Put all buffer info into string
    let bufRaw = ''
    redir => bufRaw | silent buffers | redir END

    " For each row of buffer info, just grab name and append to 'bufNames'
    let bufNames = ''
    for row in split(bufRaw, '\n')
        let splitRow = split(row, '"')
        let bufNames .= ' ' . fnamemodify(splitRow[1], ':t')
    endfor

    call Update_ctrlpCommand(bufnames)
endfun

fun! Update_ctrlpCommand(excludeNew)
    " These are default exclusions
    let excludeVim = 'backups undofiles .git [discard'
    let excludeCVS = ' CVS .#'
    if g:deprecated == 'home-laptop' 
        let excludeCore = excludeVim
    elseif g:deprecated == 'work-desktop'
        let excludeCore = excludeVim . excludeCVS
    endif


    " Create the cmd
    let oldcmd = (exists('g:ctrlp_user_command') ? g:ctrlp_user_command : '')
    let g:ctrlp_user_command = 'dir %s /-n /b /s /a-d' 
        \ . ' | findstr /v "'
        \ . excludeCore
        \ . a:excludeNew
        \ . '"'

        " /-n UNCERTAIN
        " /b lsits one per line and includes ext
        " /s lists duplicate filenames (in diff dirs)
        " /a-d means files only

        " /V means exclude the following

    " Clear cache only if there are changes
    if g:ctrlp_user_command != oldcmd
        "echom "ctrlp: clear cache"
        CtrlPClearCache
    endif
endfun

fun! ClearOutHiddenBuffers()
    wall
    for i in range(1, bufnr('$'))
        if IsBufHidden(i)
            exe 'bd ' . i
        endif
    endfor
endfun


