
" Small functions
" Base
    function! OpenFile(filename)
        let l:filename = StripWhitespace(a:filename)
        let l:currentFilename = bufname('%')

        if expand(l:currentFilename) == expand(l:filename)
            echom "Warning: Not reopening same file: " . l:filename
            return
        endif

        exe "find " . l:filename
    endfunction

    function! StripWhitespace(string)
        return substitute(a:string, '\v^\s*(.{-})\s*$', '\1', '')
    endfunction
    fun! IsBufHidden(bufNum)
        let path = expand('#'.a:bufNum)

        return (
            \buflisted(a:bufNum)
            \&& bufwinnr(a:bufNum) == -1
            \)
            "\&& !has_key(g:todos, fnamemodify(path, ':t:r'))
            "\&& !has_key(g:magiIgnoredFiles, fnamemodify(path, ':t'))
    endfun

    fun! PrintCurrFolder()
        let raw = getcwd()
        let path = fnamemodify(raw, ':t')

        "If we're at root, ie. 'C:/'
        if path == ''
            let path = raw
        endif

        return path
    endfun

" Clean these up
    fun! GetNextVisible(lnum, incr)
        " WHY - get next line, in case of folded sections
        " NOTE : incr is determined by being 1 or not 1

        let nCurr = LnumToInt(a:lnum)
        " Can't go past EOF/BOF
        if (nCurr == line('$') && a:incr == 1) || (nCurr == 1 && a:incr == -1)
            "return 0
            return nCurr
            "return -4 "Todo
        endif

        " Get next visible, being careful of folds
        let nextVisible = GetFoldBounds(nCurr, a:incr) + a:incr

        " Also for nextVisible, make sure we're on top of any fold
        if IsFolded(nextVisible) && a:incr == -1
            let nextVisible = GetFoldStart(nextVisible)
        endif

        return nextVisible
    endfun

    fun! IsEndMarker(lnum)
        if &filetype == 'todo'
            return 0
        else
            if &filetype == 'vim'
                let text = substitute(getline(a:lnum), '^\s*', '', '')
                return (text[0:2] == 'end')

            elseif &filetype == 'javascript' || &filetype == 'javascript.jsx' 
                " WHY - cover if/else or chained fctns, plus commenting
                let text = substitute(getline(a:lnum), '^\s*', '', '')
                if text[0:1] == '//' || text[0:1] == '/*'
                    return 0
                elseif text[-1:] == ';' || text[-1:] == ','
                    let text = text[:-2]
                endif

                " fml: must check BOTH
                if text[0] == '}' || text[0] == ')' || text[0] == ']' || text[0:1] == '*/'
                    return text[-1:] == '}' || text[-1:] == ')' || text[-1:] == ']'  || text[-2:] == '*/'
                endif
                return 0

            elseif &filetype == 'ruby'
                let text = substitute(getline(a:lnum), '^\s*', '', '')
                return (text[0:2] == 'end')

            endif
        endif
    endfun

    fun! Nextnonblank(lnum)
        " NOTE : no longer needed (bc want to treat whitespace as blank)
        " WHY : want nextnonblank() to accept whitespace as nonblank
        let nNext = a:lnum
        while IsBlank(nNext)
            if nNext >= line('$')
                return 0
            else
                let nNext += 1
            endif
        endwhile
        return nNext
    endfun

    fun! ProcessChar()
        hi! link Cursor HideCursor
        let char = getchar()
        if char =~ '^\d\+$'
            let char = nr2char(char)
        endif
        hi! link Cursor ShowCursor
        return char
    endfun

    fun! HasNewlines(str)
        return (match(a:str, "\n") > 0)
    endfun

" Take '.' but does NOT spit it out
    fun! IsEmptyspace(lnum) "Strange - means blank or whitespace only
        "return (getline(a:lnum) =~ '^\s*$')
        "NOTE - nextnonblank is good for EOF (edge case)
        return (a:lnum != nextnonblank(a:lnum))
    endfun

    fun! IsBlank(lnum)
        return (getline(a:lnum) == '')
    endfun

    fun! IsWhitespace(lnum)
        return (getline(a:lnum) =~ '^\s\+$')
    endfun

    fun! IsFolded(lnum)
        return (foldclosed(a:lnum) > 0)
    endfun

    fun! IsVisible(lnum)
        return (a:lnum == GetFoldStart(a:lnum))
    endfun

    fun! IsFoldable(lnum)
        " Line is a fold header that's not already folded
        " NOTE - line must be visible, could potentially be folded to another header above it
        return (!IsFolded(a:lnum) && FoldByIndentHeader(a:lnum)[0] == ">")
    endfun

" For these, can take in '.', but always return int
    fun! LnumToInt(lnum)
        return (type(a:lnum) == 0 ? a:lnum : line(a:lnum))
    endfun

    fun! GetFoldStart(lnum)
        "return (IsFolded(lnum) ? foldclosed(a:lnum) : a:lnum)
        return (!IsFolded(a:lnum) ? LnumToInt(a:lnum) : foldclosed(a:lnum))
    endfun

    fun! GetFoldEnd(lnum)
        return (!IsFolded(a:lnum) ? LnumToInt(a:lnum) : foldclosedend(a:lnum))
    endfun

    fun! GetFoldBounds(lnum, incr)
        " WHAT : get fold start/end, based on direction
        " NOTE : incr is determined by being 1 or not 1
        if !IsFolded(a:lnum)
            return LnumToInt(a:lnum)
        else
            return (a:incr == 1 ? GetFoldEnd(a:lnum) : GetFoldStart(a:lnum))
        endif
    endfun


" Big functions/utilities
function! Snakecase(word)
    " To replace highlighted camelcase: %s//\=Snakecase(submatch(0))/

    let word = substitute(a:word,'::','/','g')
    let word = substitute(word,'\(\u\+\)\(\u\l\)','\1_\2','g')
    let word = substitute(word,'\(\l\|\d\)\(\u\)','\1_\2','g')
    let word = substitute(word,'[.-]','_','g')
    let word = tolower(word)
    return word
endfunction

" Syntax highlighting
    fun! PythonSyntaxHl()
        " All operators
        syn match Type "="
        syn match Type "+"
        syn match Type "-"
        syn match Type "/"
        syn match Type "\*"
        syn match Type ">"
        syn match Type "<"
        syn match Type ":"
        syn match Type "!"

        " All delimiters
        "syn match Delimiter "("
        "syn match Delimiter ")"
        "syn match Delimiter "\["
        "syn match Delimiter "\]"
        "syn match Delimiter ","

        " Manually add functions
        syn keyword pythonBuiltin append insert
        syn keyword pythonBuiltin strip split join format
        syn keyword pythonBuiltin sleep time play floor
        hi link pythonBuiltin Function

        "syn keyword Type i
        "syn keyword Conditional i
        syn keyword Function i j
        "syn keyword Function self

    endfun

    fun! HtmlSyntaxHl()
        hi javaScript guifg=fg
        "call JsSyntaxHl()

        "syn keyword jsBuiltin console log trace p printType getType getProtoChain
        "syn keyword jsBuiltin map reduce filter forEach call apply bind
        "syn keyword jsBuiltin length join
        "syn keyword jsBuiltin max min create
        "hi link jsBuiltin Underlined
    endfun

    fun! JsSyntaxHl()
        return
        "syn clear "TODO: just make my own syntax file

        " Literals : Including strings and booleans
        hi link javaScriptNull Constant
        syn match Constant "\<\d\+\>"
        syn keyword Constant NaN

        " Operators : Booleans
        syn match Type "="
        syn match Type "!"
        syn match Type ">"
        syn match Type "<"
        syn match Type "&"
        syn match Type "|"
        syn match Type "\~"
        syn match Type "\^"

        " Operators : Math
        syn match Type "+"
        syn match Type "-"
        syn match Type "\*"
        syn match Type "\/"
        syn match Type "%"

        " Operators : Language-specific
        "syn match Type "\."
        syn match Type ";"
        syn match Type "?"
        syn match Type ":"

        " Operators : Keywords
        syn keyword jsOps var let in void of const
        syn keyword jsOps typeof instanceof new delete
        hi link jsOps Type

        " Comments (Note: keep this at the end, after operators)
        syn match javaScriptLineComment "\/\/.*" contains=@Spell,javaScriptCommentTodo
        syn region javaScriptComment start="/\*"  end="\*/" contains=@Spell,javaScriptCommentTodo

        " Special string (using <`>)
        syn region javaScriptStringT start=+`+ end=+`+ contains=javaScriptSpecial,@htmlPreproc,innerExpression
        syn region innerExpression start=+${+ end=+}+
        hi def link javaScriptStringT String

        " Functions : Special emphasis on keywords 'return', 'break', 'function'
        hi link javaScriptFunction Special
        hi link javaScriptStatement PreProc
        hi link javaScriptBranch PreProc
        " Also highlight dangerous keywords, eg. debugger, escape, alert
        hi link javaScriptReserved PreProc
        hi link javaScriptDeprecated PreProc
        hi link javaScriptMessage PreProc
        " Clear out normal keywords: window, document
        syntax clear javaScriptGlobal javaScriptMember
        syn keyword PreProc yield async await

        " Defined : Functions that are global
        syn keyword jsInternal eval call apply bind create keys hasOwnProperty isArray
        syn keyword jsInternal console log addEventListener getElementById setTimeout setInterval
        syn keyword jsInternal Math max min JSON stringify parse
        syn keyword jsInternal splice slice push pop sort indexOf concat map reduce filter forEach
        syn keyword jsInternal toString toFixed split substr
        " external: jquery and my own helper fctns
        syn keyword jsExternal extend
        syn match   jsExternal "\$"
        syn keyword jsExternal printType getType getProtoChain
        hi link javaScriptType Function
        hi link jsInternal Function
        hi link jsExternal Function

        " Use this to highlight ALL properties
        "syn match jsMine "\.\<\w\+\>"
        "hi link jsMine Function

        " Critical : 'this' is most important word in all of js
        " NOTE - put this section AFTER jzZebra's syn match
        syn keyword jsThis this arguments pv self
        hi link jsThis helpVim
        syn match jsThis "\$\<this\w*\>"
        syn match jsThis "\$$private"
        syn match jsThis "\$scope"
    endfun

    fun! TodoSyntaxHL()
        set filetype=todo
        setlocal shiftwidth=4
        syn match Identifier "^\s*#.*"
        syn match Statement "^\s*\$.*"
        syn match Type "^\s*_.*"
        syn match Special "^\s*!.*"
        syn match Comment "^\s*(.*"
    endfun

" Session
    fun! DeleteSession()
        call delete(expand(g:dir_vim . "session/default.vim"))
        call delete(expand(g:dir_vim . "session/default.vim.lock"))
        let g:session_autosave = 'no'
        exe 'source '.g:dir_myPlugins.'plugin/vimrc'
        "let g:session_autoload = 'no'
    endfun

    fun! CloseTempBuffers()
        " Go thru win and close any that are &filetype == 'help'
        let tempBuffers = {
            \'help':1,
            \'gitcommit':1,
            \'minibufexpl': 1,
            \'qf': 1
            \}
        
        for i in range(winnr('$'), 1, -1)
            let winFileType = getwinvar(i, '&filetype') 
            if has_key(tempBuffers, winFileType) || winFileType == ''
                exe i.'quit'
            endif
        endfor
    endfun

    fun! WhenSessionLoad()
        if !exists("g:sessionHasLoaded")
            let g:sessionHasLoaded = 1
            MBEOpen
        endif
    endfun

" Handling large files
    fun! HandleLargeFile(event)
        let fsize = getfsize(expand("<afile>"))
        if fsize < g:FileSizeMax && fsize != -2
            return
        endif

        if a:event == 'pre'
            " worst iniital load: folding
            "echom "fsize pre"
            setlocal foldmethod=manual

            " worst on search/jump: syntax
            "setlocal eventignore+=FileType
            "setlocal syntax=
            "set filetype=nofile
            "let &filetype = ''
            "set filetype=

            " Need to the below AFTER buf is read! wowow
            "normal! GG
            "setlocal filetype=javascript


            "set eventignore+=FileType
            "setlocal eventignore=all
            "" save memory when other file is viewed
            "setlocal bufhidden=unload
            "" is read-only (write with :w new_filename)
            "setlocal buftype=nowrite
            "" no undo possible
            "setlocal undolevels=-1
            "setlocal nofoldenable

            " Tweaks to make vim faster
                "set noswapfile
                "set eventignore +=FileType
                "setlocal undolevels=-1
                "setlocal buftype=nowrite

            "setlocal statusline=
            "syntax off

        elseif a:event == 'post'
            "echom "fsize post"
            "normal! GG
            "setlocal filetype=javascript

        endif
    endfun

" For Grep
    function! RunGrep(...)
        let query = s:formatQuery(a:000)

        call s:configureGrepCommand()

        let executed = s:executeGrep(query)

        if executed
            call s:setupGrepWindow(query)
        endi
    endfunction

    function! s:formatQuery(arguments)
        let [query, queryParams] = len(a:arguments) == 1 ?
            \s:extractQuery(a:arguments[0]) :
            \s:getQueryFromLastSearch()

        let query = s:confirmQueryHasQuotes(query)

        return query . queryParams
    endfunction

    function! s:extractQuery(input)
        let query = a:input
        let queryParams = ''

        for param in ['-i', '-w']
            let index = s:findParam(query, param)
            if index != -1
                let query = strpart(query, 0, index) . strpart(query, index+len(param)+1)
                let queryParams .= ' '.param
            endif
        endfor

        let query = StripWhitespace(query)
        call s:setHighlight(query)

        return [query, queryParams]
    endfunction

    function! s:getQueryFromLastSearch()
        let query = getreg('/')
        let queryParams = ''

        if query[0:1] == '\<' && query[-2:-1] == '\>' 
            let query = query[2:-3]
            let queryParams .= ' -w'
        endif

        if query[0:1] == '\c'
            let query = query[2:]
            let queryParams .= ' -i'
        endif

        return [query, queryParams]
    endfunction

    function! s:confirmQueryHasQuotes(query)
        let query = a:query

        if query[0] != '"' && query[0] != "'"
            let query = '"' . query
        endif

        if query[-1:] != '"' && query[-1:] != "'"
            let query .= '"'
        endif

        return query
    endfunction

    function! s:findParam(str, param)
        if a:str[:2] == a:param.' ' 
            return 0
        endif

        return match(a:str, ' '.a:param)
    endfunction

    function! s:setHighlight(query)
        let query = a:query
        if (query[0] == '"' && query[-1:] == '"') || (query[0] == "'" && query[-1:] == "'") 
            let query = query[1:-2]
        endif

        let @/ = query
    endfunction

    function! s:executeGrep(query)
        try
            let command = 'silent grep '.a:query.' *'
            echom command
            exe command
            return 1
        catch
            echom "Invalid query: ".a:query
            return 0
        endtry
    endfunction

    function! s:configureGrepCommand()
        if executable('ag')
            let &grepprg = 'ag -s --nogroup --nocolor --hidden'

            let ignored_dirs = g:my_grep_ignored_core
            let current_dir = fnamemodify(getcwd(), ':~')
            if has_key(g:my_grep_ignored_dirs, current_dir)
                let ignored_dirs += g:my_grep_ignored_dirs[current_dir]
            endif

            for ignore_dir in ignored_dirs
                let &grepprg .= ' --ignore-dir ' . ignore_dir
            endfor
        elseif g:os == 'windows'
            let &grepprg = 'findstr /n /s'
        endif
    endfunction

    function! s:setupGrepWindow(query)
        " Format result
        set hlsearch
        set foldlevel=99
        redraw!

        " Prep quickfix window
        copen
        if &filetype == "qf"
            call setwinvar(0, "&statusline", '  Found '.len(getqflist())." for [".a:query."]")
            "set ffs=dos
            "silent g/\\\$/s///
            redraw!
        endif
    endfunction

    command! -nargs=? Indexer call RunGrep(<f-args>)


" Unorgz
function! IsString(expr)
    return type(a:expr) == 1
endfunction

function! IsInteger(expr)
    return type(a:expr) == 0
endfunction

function! IsBufVisible(expr)
    if IsString(a:expr)
        let regex = '^' . a:expr . '$'
        return bufwinnr(regex) != -1
    elseif IsInteger(a:expr)
        return bufwinnr(a:expr) != -1
    endif

    echom 'WARNING: Invalid type:' . type(a:expr)
    return 0
endfunction
