
function! Commentor(type = '') abort
    " Weird logic for operator functions
    if a:type == ''
        set opfunc=Commentor
        return 'g@'
    endif
    
    let [l:start, l:end] = [line("'["), line("']")]
    let [l:l, l:r] = map(split(&commentstring, '%s', 1), {_,value -> trim(value)})
    
    " Deciding to comment/uncomment => can uncomment only if all lines are commented. Else, must comment
    let l:allCommented = s:isAllCommented(l:start, l:end, l:l, l:r)
    
    for l:i in range(l:start, l:end)
        if s:isLastLineInFoldAndBlank(l:i, l:end)
            continue
        endif

        if l:allCommented
            call s:uncommentLine(l:i, l:l, l:r)
        else
            call s:commentLine(l:i, l:l, l:r)
        endif
    endfor
endfunction

function! s:isAllCommented(start, end, l, r)
    for l:i in range(a:start, a:end)
        if s:isLastLineInFoldAndBlank(l:i, a:end)
            continue
        endif

        let l:firstChars = trim(getline(l:i))[:len(a:l)-1]
        let l:lastChars = len(a:r) == 0 ? '' : trim(getline(l:i))[-len(a:r):]
        echom len(a:r) ',' trim(getline(l:i)) ',' l:lastChars

        if l:firstChars != a:l || l:lastChars != a:r
            return 0
        endif
    endfor

    return 1
endfunction

function! s:isLastLineInFoldAndBlank(i, end)
    return a:i == a:end && IsFolded(a:i) && len(getline(a:i)) == 0
endfunction

function! s:commentLine(i, l, r) abort
    let l:fullLine = getline(a:i)

    if len(l:fullLine) == 0 "Make blank lines match rest of block
        let l:prevIndent = indent(a:i - 1)
        call setline(a:i, repeat(' ', l:prevIndent) . a:l . a:r)
    endif

    let l:nIndent = indent(a:i)
    let l:lineText = l:fullLine[l:nIndent:]
    let l:whitespace = repeat(' ', l:nIndent)
    call setline(a:i, l:whitespace . a:l . l:lineText . a:r)
endfunction

function! s:uncommentLine(i, l, r) abort
    let l:replacement = substitute(getline(a:i),  a:l, '', '')
    let l:replacement = substitute(trim(l:replacement, ' ', 2),  a:r.'$', '', '')
    call setline(a:i, l:replacement)
endfunction

