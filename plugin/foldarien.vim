
" remove using indent()
fun! FoldByIndentHeader(lnum)
    " Vim makes folds based on the output of this function
    "   0 means line is never folded
    "   1/2/3.. are fold levels. Vim folds all adjacent lines in same level or higher
    "   -1 means inline - pick lowest adjacent fold level (of nonblanks)
    "   '>' means start of fold, eg. '>3' is foldstart for level 3
    "   See more from ":help fold-expr"
    " As you might guess, this function is simple, but can be tricky

    " Prep needed info.
    "echom a:lnum
    let nCurr = a:lnum
    let indCurr = GetIndentLvl(nCurr)

    " Nextnonblank() treats whitespace as nonblank
    "let nBelow = Nextnonblank(nCurr+1)
    let nBelow = nextnonblank(nCurr+1)
    let indBelow = (nBelow == 0 ? 0 : GetIndentLvl(nBelow))


    " Folding for blank lines
    "   Normally, can treat all blanks as inline, ie -1 so vim picks lowest above/below
    "   But clever idea: have first blank after branch be folded too (!)
    if indCurr == -1
        let nAbove = nCurr - 1
        let indAbove = GetIndentLvl(nAbove)

        " If end of branch, fold to header (tricky!)
        if indAbove > indBelow
            return indBelow + 1
            "return indAbove "bad bc last fold needs to give up blank for higher level

        " In every other case, keep blanks inline
        else
            return indBelow
        endif

    " Folding for nonblank lines (simple)
    elseif indCurr < indBelow
        return '>'.(indCurr + 1)
    else
        return indCurr
    endif
endfun

fun! MyFoldText()
    let lineText = getline(v:foldstart)

    " Deal with errors
    if lineText == ''
        let lineText = 'ERROR: Blank'
    elseif lineText =~? '^\s\+$'
        let lineText ='ERROR: Whitespace'
    endif
    let lineText = substitute(lineText, "\t", "=---", "g")

    " OUTLINE : lineText(1-80) + filler(0-79) + countPadding(1-4) + count(1-4) = 85

    " START with lineText + filler
    " For line count to be formatted inline, cut off lineText
    let foldTextWidth = winwidth(0) - 13
    let foldTextWidth = (foldTextWidth > 100 ? 100 : foldTextWidth)
    let lineText = strpart(lineText, 0, foldTextWidth)
    let fillerSize = foldTextWidth - len(lineText)
    let filler = repeat(' ', fillerSize)

    " Enable below for indent guides!
    " NOTE - this section must be AFTER using strlen() bc of issues w special chars
    "if exists('g:indentLine_char')
    "    let oneIndent = repeat(' ', &shiftwidth)
    "    let replacement = g:indentLine_char . oneIndent[1:]
    "    let lineText = substitute(lineText, oneIndent, replacement, 'g')
    "    let lineText = substitute(lineText, g:indentLine_char, ' ', '')
    "endif

    " THEN do count + countpadding
    let foldCount = v:foldend - v:foldstart + 1
    let foldCountSize = float2nr(log10(foldCount))
    let foldCountPadding = repeat(' ', 5 - foldCountSize)

    " Last piece
    let fillerEnd = repeat(' ', &columns - foldTextWidth)

    return lineText . filler . foldCountPadding . foldCount . fillerEnd
endfun


" Started: 3/30/16
fun! Fold_firstInd(nStart, nEnd)
    for i in range(a:nStart, a:nEnd)
        if IsFoldable(i)
            exe i.'foldclose'
        endif
    endfor
endfun

" fix GetBranchHead()

" CLEAN
fun! FoldOpen_visual(type)
    " Visual mode is super simple
    let nStart = line("'<")
    let nEnd = line("'>")
    if a:type == 'all'
        call UnfoldAll(nStart, nEnd)
    elseif a:type == 'bylevel'
        call UnfoldLevel(nStart, nEnd)
    endif
endfun
" TODO: rename UnfoldALl to UnfoldRange (cuz unfolaall is just foldlevel==99!)
fun! UnfoldAll(nStart, nEnd)
    for l:i in range(a:nStart, a:nEnd)
        if IsFolded(l:i)
            exe l:i.'foldopen'
        endif
    endfor
endfun

fun! UnfoldLevel(nStart, nEnd)
    exe a:nStart.','.a:nEnd.'foldopen'
endfun

fun! FoldOpen(type)
    " Most straightforward situation
    if IsFolded(line('.'))
        if a:type == 'bylevel'
            foldopen
        elseif a:type == 'all'
            let nStart = GetFoldStart(line('.'))
            let nEnd = GetFoldEnd(line('.'))
            call UnfoldAll(nStart, nEnd)
        endif

    else
        let nStart = PickFoldOrigin(line('.'))
        if nStart == -2
            return
        endif

        let nEnd = GetBranchEnd(nStart)

        if a:type == 'all'
            call UnfoldAll(nStart, nEnd)
        elseif a:type == 'bylevel'
            call UnfoldLevel(nStart, nEnd)
        endif
        "echom "nStart: " . nStart . ", nEnd: " . nEnd
    endif
endfun

fun! PickFoldOrigin(nCurr)
    " Getting right start is hard part

    let nStart = GetFoldStart(a:nCurr)
    if IsEmptyspace(nStart)
        let nStart = GetNextForBlank(nStart)
    endif

    " If not on head, or on a folded line, jump up to head 
    if !IsBranchHead(nStart) || IsFolded(nStart)
        let nStart = GetBranchHead(nStart)
        if !IsBranchHead(nStart)
            echom "Error: Trying to fold a leaf"
            return -2
        endif
    endif

    return nStart

endfun


" leaf => line w/ no children
" root =>
" branch => 

fun! IsBranchHead(nCurr)
    " NOTE - It's okay if this is slow
    if IsEmptyspace(a:nCurr)
        "echom "Error: blank line"
        return 0
    else
        let indCurr = GetIndentLvl(a:nCurr)
        let nBelow = nextnonblank(a:nCurr+1)
        let indBelow = GetIndentLvl(nBelow)
        return (indCurr < indBelow ? 1 : 0)
    endif
endfun


" MANGLED
fun! GetNextForBlank(nCurr)
    "OVERALL - If blank, pick best nearest line to operate from

    let nAbove = GetNextVisible(a:nCurr,0)
    let indAbove = GetIndentLvl(nAbove)
    let nBelow = GetNextVisible(a:nCurr,1)
    let nBelow_nonblank = nextnonblank(nBelow)
    "let nBelow_nonblank = Nextnonblank(nBelow)
    let indBelow_nonblank = GetIndentLvl(nBelow_nonblank)

    if indAbove > indBelow_nonblank || nBelow_nonblank == 0
        if nBelow_nonblank == 0
            let nBelow_nonblank = line('$')
            let indBelow_nonblank = 0
        endif

        let nNew = nBelow_nonblank - 1
        while 1
            let nNew -= 1
            if nNew <= 1
                let nNew = 1
                break
            elseif GetIndentLvl(nNew) == indBelow_nonblank && !IsEmptyspace(nNew)
                break
            endif
        endwhile
        return nNew

    " Every other blank
    else
        return GetBranchHead(nBelow_nonblank)
    endif
endfun


fun! FoldClose(type)
    let nStart = PickFoldOrigin(line('.'))
    let nEnd = GetBranchEnd(nStart)
    "echom "nStart: " . nStart . ", nEnd: " . nEnd

    " Once got start, do all actions 
    if a:type == 'bylevel'
        call FoldLevel(nStart, nEnd)
    elseif a:type == 'all'
        call FoldAll_toIndStart(nStart, nEnd)
        "call Fold_firstInd(nStart, nEnd)
    endif
    return
endfun


" Actual folding action
fun! FoldLevel(nStart, nEnd)
    let maxInd = GetMaxIndent(a:nStart, a:nEnd)
    if maxInd == 0
        echom "Error: nothing to fold"
    else
        for i in range(a:nStart, a:nEnd)
            if GetIndentLvl(i) == maxInd && IsVisible(i) && !IsEmptyspace(i)
                exe i.'foldclose'
            endif
        endfor
    endif
endfun
fun! FoldAll_toIndStart(nStart, nEnd)
    "Grab visible lines, at ind above curr
    let indStart = GetIndentLvl(a:nStart)
    let lines = []
    for i in range(a:nStart, a:nEnd)
        if IsVisible(i) && !IsEmptyspace(i) && GetIndentLvl(i) > indStart
            call add(lines, i)
        endif
    endfor

    " Fold them in desc order of indentation (so bottom up)
    let lines = sort(lines,"Sort_descIndent")
    for i in lines
        if IsVisible(i)
            exe i.'foldclose'
        endif
    endfor
endfun

fun! FoldAll()
    " go thru selection and pick out all the top level headers
    call FoldAll_inHeader(nStart, nEnd)
    " find next foldable, fold it, then use getFoldEnd. REPEAT
endfun
fun! FoldAll_inHeader()
    " first line should be a header
    " TODO: instead of for-loop, do while-loop and skip sections that are already folded
    "echom "FoldAll"

    let i = a:nStart
    while i <= a:nEnd
        if IsVisible(i) && !IsEmptyspace(i) && GetIndentLvl(i) > indStart
            call add(lines, i)
            if isFolded(i)
                let i = GetFoldEnd(i)
            endif
        endif
        let i += 1
    endwhile
endfun


" Get start/end of branches
fun! GetBranchHead(nCurr)
    " Input will not be blank

    " Checked 4/11/15
    if IsRoot(a:nCurr)
        "echom "Error: Already at root"
        return a:nCurr
    endif

    let indCurr = GetIndentLvl(a:nCurr)
    let nAbove = a:nCurr
    while 1
        let nAbove -= 1
        let indAbove = GetIndentLvl(nAbove)

        if indAbove < indCurr && !IsEmptyspace(nAbove)
            return nAbove
        elseif nAbove <= 1
            return 1
        endif
    endwhile
endfun
fun! GetBranchEnd(nHead)
    " NOTE: do NOT use visible, get very end of branch
    if !IsBranchHead(a:nHead)
        "echom "Error: Can't use GetBranchEnd() on non-head"
        return a:nHead
    endif

    let indHead = GetIndentLvl(a:nHead)
    let nBelow = a:nHead
    while 1
        let nPrev = nBelow
        let nBelow = nextnonblank(nBelow+1)
        let indBelow = GetIndentLvl(nBelow)

        if nBelow == 0
            return nPrev
        elseif indBelow <= indHead
            return nPrev
        endif
    endwhile
endfun
fun! IsRoot(nCurr)
    if FoldByIndentHeader(a:nCurr) == '>1'
        return 1
    else
        return 0
    endif
endfun
fun! IsLeaf(nCurr)
    if !IsBranchHead(a:nCurr)
        return 1
    else
        return 0
    endif
endfun


" Misc other helper fctns
fun! GetMaxIndent(nStart, nEnd)
    " Checked 4/11/15
    let maxIndent = GetIndentLvl(a:nStart)
    for i in range(a:nStart, a:nEnd)
        if IsVisible(i) && GetIndentLvl(i) > maxIndent
            let maxIndent = GetIndentLvl(i)
        endif
    endfor
    return maxIndent
endfun
fun! IsAnyFolded(nStart, nEnd)
    " Checked 4/11/15
    for i in range(a:nStart, a:nEnd)
        if IsFolded(i)
            return 1
        endif
    endfor
    return 0
endfun
fun! Sort_descIndent(line1, line2)
    return GetIndentLvl(a:line2) - GetIndentLvl(a:line1)
endfun



" EXPERIMENTS
    fun! EnableFctns_forCppMode()
        "These fctns override above fctns for cpp mode
        " diff is the use FoldByIndentHeader() to get flvl

        fun! GetBranchEnd(nHead)
            " assuming start at header
            " method 1. keep going, until hits same header or less
            "let fdata = FoldByIndentHeader(a:nHead)
            "if fdata[0] != '>'
            if !IsBranchHead(a:nHead)
                echom "Error: Tried GetBranchEnd on a non-head"
                return a:nHead
            endif

            let flvl = FoldByIndentHeader(a:nHead)[1:]
            let nBelow = a:nHead
            while 1
                let nBelow += 1
                let fdataBelow = FoldByIndentHeader(nBelow)

                if nBelow >= line('$')
                    return line('$')

                elseif fdataBelow[0] == '>' && fdataBelow[1:] <= flvl
                    return nBelow-1
                elseif fdataBelow < flvl
                    return nBelow-1
                endif
            endwhile
        endfun

        fun! GetBranchHead(nCurr)
            " nCurr can be anywhere except blank:
            "   root header, non-root header, leaf
            " special case: foldclose if non-root header AND folded

            if IsRoot(a:nCurr)
                "echom "Error: Already at root"
                return a:nCurr
            elseif IsBranchHead(a:nCurr)
                let flvl = FoldByIndentHeader(a:nCurr)[1:]
                let mode = 'header'
            " else leaf
            else
                let flvl = FoldByIndentHeader(a:nCurr)
                let mode = 'leaf'
            endif

            " Loop to header above
            let nAbove = a:nCurr
            while 1
                let nAbove -= 1
                let fdataAbove = FoldByIndentHeader(nAbove)

                if nAbove <= 1
                    return 1

                " If header AND if above
                elseif fdataAbove[0] == '>' &&
                \ ( (mode == 'header' && fdataAbove[1:] < flvl)
                \ || (mode == 'leaf' && fdataAbove[1:] <= flvl) )
                    return nAbove
                endif
            endwhile

        endfun


        "" NOTES FOR SPEC
        " Fold open
        " normal vs visual
        " everythingInFold vs. onlyOneFoldLevel
        " root header vs. non-root header vs. leaf vs. blank
    endfun

    "if g:cpp_mode
        "call EnableFctns_forCppMode()
    "endif


" New method of folding
    " Helper fctns
    fun! GetIndentLvl(lnum)
        if a:lnum <= 0 || a:lnum > line('$')
            "echom 'ERROR: GetIndentLvl() got bad input'
            return -4 "INPUT
        endif

        if IsEmptyspace(a:lnum)
            return -1 "Keep this at -1 for FoldByIndentHeader()
        "elseif &filetype == 'todo' || (g:machine == 'home-laptop' && line('$') > 1000)
        "    return (indent(a:lnum) / &shiftwidth)
        else
            return (indent(a:lnum) / &shiftwidth) + IsEndMarker(a:lnum)
        endif
    endfun

    fun! FindNextOfInd_nonblank(nCurr, ind, onlyEqual)
        if a:ind == -1
            echom 'ERROR: FindNext..() will not search for a blankline'
            return -1 "BLANKLINE
        elseif a:ind < 0 || a:nCurr < 0 || a:nCurr >= line('$')
            echom 'ERROR: FindNext..() got bad input'
            return -4 "INPUT
        endif

        if a:onlyEqual
            for i in range(a:nCurr+1, line('$'))
                if GetIndentLvl(i) == a:ind
                    return i
                endif
            endfor

        else
            for i in range(a:nCurr+1, line('$'))
                if !IsEmptyspace(i) && GetIndentLvl(i) <= a:ind
                    return i
                endif
            endfor
        endif
        return -2 "PAST EOF
    endfun


    " The most impt fctn, needs to be robust. (Tries to make fold if it can)
    fun! MakeFold(nStart)
        " NOTE - error handling should be done in top-level fctn
        if a:nStart <= 0 || a:nStart >= line('$')
            echom 'ERROR: MakeFold() got bad input'
            return -4 "INPUT
        elseif IsFolded(a:nStart) "Already folded?
            return a:nStart
        endif

        let indStart = GetIndentLvl(a:nStart)
        if indStart == -1
            echom 'ERROR: MakeFold() cannot start on a blankline'
            return a:nStart
        endif

        " Here is the key
        let nEnd = FindNextOfInd_nonblank(a:nStart, indStart, 0)
        if nEnd == -2 "PAST EOF
            let nEnd = prevnonblank(line('$'))
        else
            let nEnd = prevnonblank(nEnd-1)
        endif

        " Fold or skip?
        if GetIndentLvl(nEnd) > indStart
            " Here, impl my special feature: fold one blank
            if nEnd != line('$')
                let foldOneBlank = nEnd + 1
                if IsEmptyspace(foldOneBlank)
                    let nEnd += 1
                endif
            endif

            exe a:nStart.','.nEnd.'fold'
            return nEnd
        else
            return a:nStart
        endif
    endfun


    fun! Fold_buf(lvl)
        set foldmethod=manual
        normal! zE

        if a:lvl < 0 || a:lvl > 99
            echom "ERROR: SetFoldLevel() got bad input"
            return
        elseif a:lvl == 99
            normal! zE
        else
            call Fold_range(1, line('$'), a:lvl)
        endif
    endfun


    fun! Fold_all()
        if !IsFolded(line('.'))
            call MakeFold(line('.'))
        endif
    endfun

    fun! Unfold_all()
        if IsFolded(line('.'))
            normal! zd
        endif
    endfun

    fun! Unfold_level()
        if IsFolded(line('.'))
            let nStart = GetFoldStart(line('.'))
            let nEnd = GetFoldEnd(line('.'))
            let indLvl = GetIndentLvl(nStart)
            normal! zd
            call Fold_range(nStart+1, nEnd, indLvl+1)
        endif
    endfun

    fun! Fold_range(nStart, nEnd, indLvl)
        let nextLine = nextnonblank(a:nStart)
        while 1
            let nextLine = MakeFold(nextLine)
            let nextLine = FindNextOfInd_nonblank(nextLine, a:indLvl, 1)
            if nextLine == -2
                return
            elseif nextLine < 0
                echom "ERROR: Fold_buf() had an issue"
                return
            elseif nextLine >= a:nEnd
                return
            endif
        endwhile
    endfun

    fun! TestingManualFolding()
        set foldmethod=manual
        normal! zE

        " CREATE - zf{motion}
        " zF
        " :{range}fold
        " zd - delete fold
        " zD - delete folds recursively
        " zE - elim all folds
        " zx ?? revert all to foldlevel

        "FoldOpen - file vs inFold vs. byLevel
        "FoldClose -  file inFold vs. byLevel

        " VERSION 1 - put in all folds with BufRead (same as current!)
        " VERSION 2 - ONLY MAKE FOLDS WHEN NEEDED (oooh, interesting)

    endfun
    " notes
        " PRO
        " faster to load buf into win (!)

        " CON
        " defs faster to load file
        " but faster to 

        " RULE: blankline results in error: -1
        " RULE: PAST EOF results in error: -2
        " RULE: Can't start on blank and won't stop at a blank
        "set foldmethod=manual




"Key maps
    nnoremap <silent> gj :call FoldClose('all')<cr>
    nnoremap <silent> gk :call FoldClose('bylevel')<cr>
    nnoremap <silent> gl :call FoldOpen('bylevel')<cr>
    nnoremap <silent> g; :call FoldOpen('all')<cr>

    " NOTE - I never use visual close
    "vnoremap <silent> gj :<c-u>call FoldClose('all')<cr>
    "vnoremap <silent> gk :<c-u>call FoldClose('bylevel')<cr>
    vnoremap <silent> gl :<c-u>call FoldOpen_visual('bylevel')<cr>
    vnoremap <silent> g; :<c-u>call FoldOpen_visual('all')<cr>

    noremap <silent> gm :set foldlevel=0<cr>
    noremap <silent> g, :set foldlevel=1<cr>
    noremap <silent> g. :set foldlevel=2<cr>
    noremap <silent> g/ :set foldlevel=99<cr>

    " OLD
    "nnoremap <silent> gj :call Fold_all()<cr>
    "nnoremap <silent> gk :call Fold_all()<cr>
    "nnoremap <silent> gl :call Unfold_level()<cr>
    "nnoremap <silent> g; :call Unfold_all()<cr>
    "
    "noremap <silent> gm :call Fold_buf(0)<cr>
    "noremap <silent> g, :call Fold_buf(1)<cr>
    "noremap <silent> g. :call Fold_buf(2)<cr>
    "noremap <silent> g/ :call Fold_buf(99)<cr>


"set foldmethod=manual
"normal! zE
set foldtext =MyFoldText()
set foldmethod=expr
set foldexpr=FoldByIndentHeader(v:lnum)

