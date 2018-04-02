" NOTE: This plugin lets you jump lines based on indents
    " It has some nice features:
    "* Smart behavior in visual mode
    "* Supports operators intelligently
    "* Behaves well around folded sections (actually tricky)
    "* Can move column left/right to change indent that's jumped (!)
    "* If you jump to EOF/BOF, saves prev location to go back easily (!)
    "* Extensively tested and seems robust (unsure about tabs)


fun! GetIndent(lnum, checkDividers)
    " If jump goes all the way to BOF/EOF, save indent so you can go back
        " 0/4/8.. is ind for 4sp
        " 0/2/4.. is ind for 2sp
        " -1 for blank lines
        " -2 for dividers (eg. '===')

    if IsEmptyspace(a:lnum)
        return -1
    elseif a:checkDividers && getline(a:lnum)[:-2] =~ '^\s*=\+$'
        return -2
    else
        return indent(a:lnum)
    endif
endfun

fun! Jumplivion(incr, modes, type)
    let EOF = line('$')
    " Section 1: Get correct indent level, line #, column #
        " Start with defaults
            let nStart = GetFoldStart(line('.'))
            let indStart = GetIndent(nStart, a:type != 'headers')

        " Any keymap that calls a fctn cancels visual mode
            " and *always" leaves cursor at start of selection*
            " To get correct nCurr, call visual and escape out
            if a:modes == 'v'
                "echo "1 visual curr: " . line('.') . " top: ".line('w0')

                execute "normal! gv\<esc>"
                let nStart = GetFoldStart(line('.'))
                let indStart = GetIndent(nStart, a:type != 'headers')
            endif

        " FEATURE 3 = If at BOF/EOF, jump back to saved indent
            if g:Jumplivion_saveIndent != -3 
                if line('.') == 1 || GetFoldEnd(line('.')) == line('$')
                    let indStart = g:Jumplivion_saveIndent
                endif
                let g:Jumplivion_saveIndent = -3 " Reset after one use
            endif

    " Section 2: Determine type of movement
        " Look at next line
            let nNext = GetNextVisible(nStart, a:incr)
            let indNext = GetIndent(nNext, a:type != 'headers')

        " Default movement is to jump by same indent, or diff indent
            if a:type == 'indents'
                if indStart == indNext
                    let flag = "sameSection"
                else
                    let flag = "diffSection"
                endif

        " If headermode == 1, go up to branch head 
            elseif a:type == 'headers'
                let flag = a:type

                " If blank, move to root
                if IsEmptyspace(nStart)
                    let nEnd = GetNextVisible(nStart, a:incr)
                    if a:incr == 1
                        let nEnd = nextnonblank(nEnd)
                    else
                        let nEnd = prevnonblank(nEnd)
                    endif
                    call cursor(nEnd, indent(nEnd)+1)
                    return
                endif

                " If already at root, just do nothing
                if a:incr == -1 && indent(nStart) == 0
                    "echo 'ERROR: Already at root'
                    return
                endif

                if a:incr == 1 && (indStart == indNext || indNext == -1)
                    let indStart -= &shiftwidth
                endif
            endif

    " Section 3: Main loop of movements
        "echom 1
        "echom 'nStart '.nStart . ', indStart' . indStart
        while 1
            "echom nNext
            "echom 'nNext '.nNext .', indNext' . indNext
            " Check whether next line fits movement condition
            if nNext <= 1 || nNext >= line('$')
                let g:Jumplivion_saveIndent = indStart
            endif

            if (flag == "sameSection" && indNext != indStart)
                \ || (flag == "diffSection" && indNext == indStart)
                \ || (flag == 'headers' && a:incr == -1 && !IsEmptyspace(nNext) && indNext < indStart)
                \ || (flag == 'headers' && a:incr == 1 && ((!IsEmptyspace(nNext) && indNext <= indStart) || nNext == line('$')))
                return Jumplivion_mover(flag, a:modes, a:incr, nNext, nStart, indStart)
            elseif nNext <= 1
                return Jumplivion_mover("none", a:modes, a:incr, 1, nStart, indStart)
            elseif nNext >= line('$')
                return Jumplivion_mover("none", a:modes, a:incr, EOF, nStart, indStart)
            endif

            " Grab next line to check
            let nNext = GetNextVisible(nNext, a:incr)
            let indNext = GetIndent(nNext, a:type != 'headers')
        endwhile
endfun

fun! Jumplivion_mover(flag, modes, incr, nNext, nStart, indStart)
    " Start with the final line
        let nEnd = a:nNext

    " If moving by same indent, ended when hit first diff indent - so need to go back one line
        if a:flag == "sameSection"
            let nEnd = GetNextVisible(nEnd, -a:incr)
        elseif a:flag == 'headers' && a:incr == 1
            " Method 1
            let nEnd = GetNextVisible(nEnd, -a:incr)
            let nEnd = prevnonblank(nEnd)
            let nEnd = GetFoldStart(nEnd)

            if nEnd != a:nNext 
                let indGoal = a:indStart + &shiftwidth
                if indent(nEnd) != indGoal
                    " Keep moving up
                    while 1
                        if nEnd <= a:nStart || indent(nEnd) == indGoal
                            break
                        endif
                        let nEnd -= 1
                    endwhile
                endif
            endif

        endif

    " Normal mode movement
        if a:modes == 'n'
            " no special action here - go straight to move below

    " Visual selection
        elseif a:modes == 'v'
            "echo "2 visual curr: " . line('.') . " top: ".line('w0')
            normal! gv

            " FEATURE 2: For going up as diff, and only single line (think about it)
            "let vLen = line("'>") -line("'<") +1
            "if a:flag == "diffSection" && a:incr == -1 && vLen == 1
            "    "echom "singleline up diff"
            "    execute "normal! \<esc>"
            "    normal! kV
            "endif

    " Operator-pending
        elseif a:modes == 'o'
        " Pick an intelligent start and end
            "if a:flag == "diffSection"
            "    if a:incr == 1
            "        let nEnd = GetNextVisible(nEnd, -a:incr)
            "    elseif a:incr == -1
            "        normal! k
            "    endif
            "endif

        " Careful with folds
            if a:incr == 1 && IsFolded(nEnd)
                let nEnd = GetFoldBounds(nEnd, a:incr)
            endif

        " For going up, just treat like going dn
            if a:incr == -1
                let temp = nEnd
                let nEnd = GetFoldEnd('.')
                call cursor(temp, 0)
            endif
        " Operators work well with visual mode
            normal! V
        endif

    " Finally, actually move
        "echom 'ending start'.line('.')
        "echom 'ending end'.nEnd

        let winBoundsOld = line('w0')
        call cursor(nEnd, indent(nEnd)+1)
        let winBoundsNew = line('w0')
        let lenVisualBlock = line("'>") - line("'<") + 1

        " Get correct position of win
        if a:modes == 'n' && winBoundsOld != winBoundsNew "Did screen move?
            exe (a:incr == 1 ? 'normal! zb' : 'normal! zt')
        elseif a:modes == 'v' && (lenVisualBlock > winheight(0) || winBoundsOld != winBoundsNew)
            normal! zz
        endif

        " Save movement in jump history
        normal! m`
        exe "normal! \<c-o>"

        return 
endfun


let g:Jumplivion_saveIndent = -3
" Easy key maps
    let g:Jumplivion_easykeymaps = 1
    let g:Jumplivion_key_indentsUp = ','
    let g:Jumplivion_key_indentsDn = '.'
    let g:Jumplivion_key_headersUp = 'm'
    let g:Jumplivion_key_headersDn = 'M'

    if exists("g:Jumplivion_easykeymaps")
        let types = [
        \   [g:Jumplivion_key_indentsUp, -1, "'indents'"], 
        \   [g:Jumplivion_key_indentsDn, 1, "'indents'"], 
        \   [g:Jumplivion_key_headersUp, -1, "'headers'"], 
        \   [g:Jumplivion_key_headersDn, 1, "'headers'"], 
        \]

        for Mode in ['n', 'v', 'o']
            for type in types
                exe Mode.'noremap <silent>'.type[0].' :<c-u>call Jumplivion('.type[1].",'".Mode."',".type[2].')<cr>'
            endfor
        endfor
    endif

