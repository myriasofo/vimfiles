" NOTE: This plugin maps a bunch of functionality to the 's' key
"       Since 's' is easy to press, I put my most impt maps here
" why use process key, instead of just mappings?

fun! ScoutKey()
    let char = ProcessChar()

    if char == "\<esc>"
        echom 'ScoutKey: Cancelled'

    elseif char == 'y'
        " Open up vimrc
        if expand('%:t') != 'vimrc'
            if exists("g:dir_myPlugins")
                exe 'edit '.g:dir_myPlugins.'plugin/vimrc'
            else
                edit ~/vimrc
            endif
        endif
    elseif char == 'u'
        call RunCode()
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
        set wrap!
    elseif char == 'j'
        exe "normal! \<c-w>h"
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
        "call SetupWorkspace(g:todos_path.list, g:todos_path.temp1)
        call LoadFile(g:dir_palettes . 'flux.to')
    elseif char == 'm'
        call LoadFile(g:todos_path.list)
    elseif char == ','
        call LoadFile(g:todos_path.temp1)
    elseif char == '.'
        call LoadFile(g:todos_path.temp2)
    elseif char == '/'
        "call SetupWorkspace(g:todos_path.temp1, g:todos_path.temp2)
        call LoadFile(g:dir_palettes . 'timeLog.to')


    elseif char == 'e'
        call RemoveAllBuffers()
    elseif char == 'a'
        let char = ProcessChar()
        call OpenBuffer(char)
    elseif char == 's'
        redraw!
    elseif char == 'd'
        let char = ProcessChar()
        call RemoveBuffer(char)
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
        let char =ProcessChar()
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

fun! RunCode()
    " Save prev win
    let winPrev = winnr()

    if &filetype == 'python'
        update
        try
            call ExecuteInShell('python3 %', 'right')
        catch
            call ExecuteInShell('python %', 'right')
        endtry

    elseif &filetype == 'javascript'
        update
        call ExecuteInShell('node %', 'right')

    "elseif &filetype == 'stata'
    "    update
    "    "silent! !start /min "C:\Users\Abe\Dropbox\Archives\static\stata-nppp\rundo.exe" "%:p"
    "    let dir_runStata = 'C:\Users\Abe\Dropbox\Archives\static\stata-nppp\'
    "    silent! exe '!start /min "'.dir_runStata.'rundo.exe" "%:p"'

    elseif &filetype == 'vim'
        update
        if exists("g:dir_myPlugins")
            exe 'source '.g:dir_myPlugins.'plugin/vimrc'
        else
            source ~/vimrc
        endif

    elseif &filetype == 'todo' && expand('%:t') == 'timeLog.to'
        :w
        call ExecuteInShell('python ' . g:dir_dev . '/analyzeLog/analyzeLog.py', 'right')

    "elseif &filetype == 'r'
    "elseif &filetype == 'tex'
    "elseif &filetype == 'java'
    "elseif &filetype == 'cpp'
    " NOTE: must put in sep plugin, like done in scoutkey
    else
        echom 'ScoutKey: Filetype not supported for RunCode()'
    endif

    " Return to prev win
    exe winPrev.' wincmd w'
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

fun! ExecuteInShell(cmd, direction)
    " Expand all vim symbols in cmd
    let cmd = join(map(split(a:cmd), 'expand(v:val)'))

    " If output win exists, switch. If not, create new
    "let output_bufname = fnameescape(cmd)
    "let winNum = bufwinnr('^'.cmd.'$')
    let output_bufname = "[Shell output"
    let winNum = bufwinnr(output_bufname)
    if winNum != -1
        exe winNum.'wincmd w'
    else
        if a:direction == 'down'
            exe 'belowright new '.output_bufname
        elseif a:direction=='right'
            exe 'belowright vs new '.output_bufname
        endif
    endif

    " Set options for this special win
    setlocal buftype=nowrite bufhidden=wipe noswapfile nonumber nofoldenable
    "nobuflisted 

    " Run cmd, paste output
    exe 'silent %!'.cmd

    " If going down, resize to fit output
    if a:direction == 'down'
        resize 5
        "exe 'resize '.line('$')
        "redraw
    endif
endfun
command! -complete=shellcmd -nargs=+ Shell call ExecuteInShell(<q-args>)
fun! OpenBuffer(key)
    if !exists("g:convertMbeToBuf")
        return
    endif

    if has_key(g:convertMbeToBuf, a:key)
        let realBufNum = g:convertMbeToBuf[a:key]
        exe 'b '.realBufNum
    else
        echom "ERROR: No such key for buffer"
    endif
endfun

fun! RemoveBuffer(key)
    " NOTE - is used with MBE's buf keys, so will only remove hidden bufs 
    " (ie. never have to worry about removing active bufs)
    if !exists("g:convertMbeToBuf")
        return
    endif

    if has_key(g:convertMbeToBuf, a:key)
        let realBufNum = g:convertMbeToBuf[a:key]
        "call Spacework_addFileToWs("[unloaded", bufname(realBufNum))
        exe 'bd ' realBufNum
    else
        echom "ERROR: No such key for buffer"
    endif
endfun

fun! RemoveAllBuffers()
    wall

    let unloadedFiles = []
    for i in range(1, bufnr('$'))
        if buflisted(i) && bufwinnr(i) == -1
            let bufPath = expand('#'.i.':t')
            let splitTail = split(bufPath, '\.')
            if len(splitTail) != 0 && !has_key(g:todos_path, splitTail[0]) && !has_key(g:MBE_IGNORED_FILES, bufPath)
                call add(unloadedFiles, bufPath)
                exe 'bd '.i
            endif
        endif
    endfor

    " IDEA - actually replace, not just add
    "call Spacework_replaceWs("[unloaded", unloadedFiles)
endfun


