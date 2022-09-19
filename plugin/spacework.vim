
" Expected format for file
    " $ text to display
    " ( comment
    " % file link (eg. 'linkName: filePath')
    " : use to split linkName vs filePath
    " & for filePath, use a vim varaible for path (eg. &g:dirNotes/dilig.to)
    " @ command to execute

    let s:CHAR_DISPLAY_TEXT = '$'
    let s:CHAR_COMMENT = '('
    let s:CHAR_FILELINK = '%'
    let s:CHAR_FILELINK_SPLIT = ':'
    let s:CHAR_FILELINK_VAR = '&'
    let s:CHAR_COMMAND = '@'
    let s:PADDING_LEFT = '  '

    " Settings
    let g:Spacework#configLocation = g:dir_notes . '_configs/spacework.to'
    let s:jumpkeys = 'abcdefghijmnopqrstuvwxyz'


fun! Spacework()
    let l:mapKeyToFile = Spacework#ExtractConfig()
    call s:getInput(l:mapKeyToFile)
    redraw "Stops 'Press ENTER or...'
endfun

fun! Spacework#ExtractConfig(shouldPrint=1)
    let l:mapKeyToFile = {}
    call s:resetJumpKeys() "TODO: easier method?

    let printLine = ''
    for l:line in s:readConfig()
        let line = StripWhitespace(l:line)
        let firstChar = line[0]

        if firstChar == s:CHAR_COMMENT
            continue

        elseif firstChar == ''
            let printLine = ''

        elseif firstChar == s:CHAR_DISPLAY_TEXT
            let printLine = line[2:]

        elseif firstChar == s:CHAR_FILELINK
            " TODO: could turn below into a sep fctn?
            let [fileDisplayText, filePath] = SplitOnce(line[1:], ':')

            let jumpKey = s:getNextJumpKey()
            let l:mapKeyToFile[jumpKey] = filePath

            let printLine = jumpKey . ': ' . StripWhitespace(fileDisplayText)
        else
            let printLine = 'ERROR: Bad line - ' . line
        endif

        if a:shouldPrint
            echo s:PADDING_LEFT . printLine . "\n"
        endif
    endfor

    return l:mapKeyToFile
endfun

fun! s:readConfig()
    try
        return readfile(g:Spacework#configLocation)
    catch
        return []
    endtry
endfun

fun! s:resetJumpKeys()
    let s:jumpKey = -1
endfun

fun! s:getNextJumpKey()
    let s:jumpKey += 1
    return s:jumpkeys[s:jumpKey]
endfun

fun! s:getInput(jumpList)
    while 1
        let char = ProcessChar()

        if has_key(a:jumpList, char)
            let filePath = a:jumpList[char]
            call OpenFile(filePath)
            return

        elseif char == "\<esc>"
            return

        else
            echo '  ERROR: "'.char.'" is not a key. Press <esc> or try again: '
        endif

    endwhile
endfun


