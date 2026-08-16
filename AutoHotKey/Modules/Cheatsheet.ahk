; ==============================================================================
; [ MODULE: DYNAMIC CHEATSHEET PARSER & GUI ]
; ==============================================================================

global cheatGui := ""

ShowCheatSheet() {
    global cheatGui
    
    if (cheatGui) {
        if DllCall("IsWindowVisible", "Ptr", cheatGui.Hwnd) {
            cheatGui.Hide()
        } else {
            cheatGui.Show("AutoSize Center")
            WinActivate("ahk_id " cheatGui.Hwnd)
        }
        return 
    }
    
    ; ==============================================================================
    ; 1. DATA EXTRACTION (The Aesthetic Masterpiece Parser)
    ; ==============================================================================
    cheatText := ""
    currentCategory := ""
    currentSubCategory := ""
    
    filesToParse := [A_ScriptDir "\Modules\Hotstrings.ahk", A_ScriptDir "\Modules\Keybindings.ahk"]
    
    for _, currentFile in filesToParse 
    {
        if !FileExist(currentFile)
            continue
            
        fileData := FileRead(currentFile)
        
        Loop Parse, fileData, "`n", "`r"
        {
            line := Trim(A_LoopField)
            if (line == "" || InStr(line, "[ FUNCTION LIBRARY ]"))
                continue
            
            ; A. Detect Categories
            if (RegExMatch(line, 'i)^\s*;\s*\[(.*?)\]', &match)) {
                currentCategory := Trim(match[1])
                currentSubCategory := ""
                cheatText .= "►CAT_TOP`n►CAT_TXT:" StrUpper(currentCategory) "`n►CAT_BOT`n"
                continue
            }
            ; B. Detect Sub-Categories
            else if (RegExMatch(line, 'i)^\s*;\s*---\s*(.*?)\s*---', &match)) {
                cleanSub := Trim(match[1], " -")
                if (cleanSub != "") {
                    currentSubCategory := cleanSub
                    cheatText .= "►SUB_TXT:  ■ " currentSubCategory "`n"
                }
                continue
            }
            
            ; C. Detect Hotkeys (::) OR Leader Keys (case) - IF THEY HAVE A COMMENT
            if (RegExMatch(line, 'i)(?:\bcase\s+"([^"]+)"|[$#\^!+<>\w]+::).*?;\s*(.*)', &match)) {
                isLeaderKey := (match[1] != "")
                fullComment := Trim(match[2])
                
                if (isLeaderKey) {
                    char := StrUpper(match[1])
                    desc := Trim(RegExReplace(fullComment, "^.*?:", "")) 
                    finalText := "Press " char " -> " desc
                } else {
                    if RegExMatch(fullComment, "^(.*?):\s*(.*)", &parts) {
                        finalText := Trim(parts[1]) " -> " Trim(parts[2])
                    } else {
                        finalText := fullComment
                    }
                }
                
                prefix := (currentSubCategory != "") ? "    ├─ " : "    "
                cheatText .= prefix . finalText . "`n"
            }
        }
    }
    
    ; ==============================================================================
    ; 2. BRUTE-FORCE COLUMN BALANCING (Maximum Font Size Algorithm)
    ; ==============================================================================
    cheatText := Trim(cheatText, "`n`r")
    lines := StrSplit(cheatText, "`n")
    totalLines := lines.Length
    
    safeBreaks := []
    For index, line in lines {
        if (index == 1)
            continue
            
        isHeader := (SubStr(line, 1, 5) == "►CAT_" || SubStr(line, 1, 5) == "►SUB_")
        prev1 := (index > 1) ? (SubStr(lines[index-1], 1, 5) == "►CAT_" || SubStr(lines[index-1], 1, 5) == "►SUB_") : false
        prev2 := (index > 2) ? (SubStr(lines[index-2], 1, 5) == "►CAT_" || SubStr(lines[index-2], 1, 5) == "►SUB_") : false
        
        if !(isHeader || prev1 || prev2)
            safeBreaks.Push(index)
    }
    
    bestMax := 99999
    bestSplit1 := Max(2, totalLines // 3)
    bestSplit2 := Max(3, (totalLines // 3) * 2)
    
    For _, s1 in safeBreaks {
        For _, s2 in safeBreaks {
            if (s2 <= s1)
                continue
                
            c1 := s1 - 1
            c2 := s2 - s1
            c3 := totalLines - s2 + 1
            
            currentMax := Max(c1, c2, c3)
            
            if (currentMax < bestMax) {
                bestMax := currentMax
                bestSplit1 := s1
                bestSplit2 := s2
            }
        }
    }
    
    col1 := [], col2 := [], col3 := []
    currentCol := 1
    maxCol1Len := 0, maxCol2Len := 0, maxCol3Len := 0
    
    For index, line in lines {
        if (index == bestSplit1)
            currentCol := 2
        else if (index == bestSplit2)
            currentCol := 3
            
        actualLen := StrLen(line)
        if (SubStr(line, 1, 8) == "►CAT_BOT" || SubStr(line, 1, 8) == "►CAT_TOP")
            actualLen := 0 
        else if (SubStr(line, 1, 9) == "►CAT_TXT:")
            actualLen := StrLen(SubStr(line, 10)) + 4 
        else if (SubStr(line, 1, 9) == "►SUB_TXT:")
            actualLen := StrLen(SubStr(line, 10))
            
        if (currentCol == 1) {
            col1.Push(line)
            if (actualLen > maxCol1Len)
                maxCol1Len := actualLen
        } else if (currentCol == 2) {
            col2.Push(line)
            if (actualLen > maxCol2Len)
                maxCol2Len := actualLen
        } else {
            col3.Push(line)
            if (actualLen > maxCol3Len)
                maxCol3Len := actualLen
        }
    }
    
    maxRows := Max(col1.Length, col2.Length, col3.Length)
    if (maxRows == 0)
        maxRows := 1
        
    ; ==============================================================================
    ; 3. THE PERFECT GRID BUILDER
    ; ==============================================================================
    gapSize := 3 
    gapStr := ""
    Loop gapSize
        gapStr .= " "
        
    PadRight(str, len) {
        padLen := len - StrLen(str)
        if (padLen > 0) {
            Loop padLen
                str .= " "
        }
        return str
    }
    
    ProcessCell(cellValue, colMax) {
        if (SubStr(cellValue, 1, 8) == "►CAT_TOP" || SubStr(cellValue, 1, 8) == "►CAT_BOT") {
            lineStr := ""
            Loop colMax
                lineStr .= "="
            return lineStr
        }
        if (SubStr(cellValue, 1, 9) == "►CAT_TXT:") {
            txt := SubStr(cellValue, 10)
            spaces := (colMax - StrLen(txt)) // 2 
            padLeft := ""
            Loop Max(0, spaces)
                padLeft .= " "
            return PadRight(padLeft . txt, colMax)
        }
        if (SubStr(cellValue, 1, 9) == "►SUB_TXT:") {
            return PadRight(SubStr(cellValue, 10), colMax)
        }
        return PadRight(cellValue, colMax)
    }
    
    combinedText := "" 
    
    Loop maxRows {
        left  := (A_Index <= col1.Length) ? col1[A_Index] : ""
        mid   := (A_Index <= col2.Length) ? col2[A_Index] : ""
        right := (A_Index <= col3.Length) ? col3[A_Index] : ""
        
        l_fmt := ProcessCell(left, maxCol1Len)
        m_fmt := ProcessCell(mid, maxCol2Len)
        r_fmt := ProcessCell(right, maxCol3Len)
        
        combinedText .= l_fmt . gapStr . m_fmt . gapStr . r_fmt . "`n"
    }
    
    combinedText := Trim(combinedText, " `n`r")
    combinedText := StrReplace(combinedText, "&", "&&")
    
    ; ==============================================================================
    ; 4. NATIVE OS TEXT MEASUREMENT 
    ; ==============================================================================
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    activeMonitor := 1
    
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
        if (mX >= mLeft && mX <= mRight && mY >= mTop && mY <= mBottom) {
            activeMonitor := A_Index
            break
        }
    }
    
    MonitorGetWorkArea(activeMonitor, &waLeft, &waTop, &waRight, &waBottom)
    monWidth := waRight - waLeft
    monHeight := waBottom - waTop
    
    maxGuiW := Floor(monWidth * 1)
    maxGuiH := Floor(monHeight * 1) 
    
    fontSize := 36 
    textW := 0, textH := 0
    
    Loop {
        tempGui := Gui("-DPIScale") 
        tempGui.SetFont("s" fontSize " w700", "Consolas")
        
        tempText := tempGui.Add("Text", "", combinedText)
        tempText.GetPos(,, &textW, &textH)
        tempGui.Destroy()
        
        reqGuiW := textW + 40
        reqGuiH := textH + 40
        
        if ((reqGuiW <= maxGuiW) && (reqGuiH <= maxGuiH)) || (fontSize <= 8)
            break
            
        fontSize-- 
    }
    
    ; ==============================================================================
    ; 5. UI RENDERING & PERFECT CENTERING
    ; ==============================================================================
    cheatGui := Gui("+AlwaysOnTop -Caption -Border -DPIScale", "AHK Master Cheatsheet")
    cheatGui.BackColor := "1E1E1E" 
    cheatGui.SetFont("s" fontSize " w700", "Consolas")  
    
    cheatGui.MarginX := 20
    cheatGui.MarginY := 20
    
    cheatGui.Add("Text", "w" textW " h" textH " Background1E1E1E cD4D4D4", combinedText)
    focusTrap := cheatGui.Add("Edit", "xp yp w0 h0 Background1E1E1E -Border")
    
    cheatGui.OnEvent("Escape", (*) => cheatGui.Hide())
    cheatGui.OnEvent("Close", (*) => cheatGui.Hide())
    
    cheatGui.Show("Hide AutoSize x" waLeft " y" waTop)
    cheatGui.GetPos(,, &realW, &realH)
    
    guiX := waLeft + (monWidth - realW) // 2
    guiY := waTop + (monHeight - realH) // 2
    
    cheatGui.Show("x" guiX " y" guiY)
    WinActivate("ahk_id " cheatGui.Hwnd)
    focusTrap.Focus()
}

; ==============================================================================
; 6. THE FOCUS FIX (Global Escape Override)
; ==============================================================================
#HotIf WinExist("AHK Master Cheatsheet")
~Escape:: {
    global cheatGui
    if (cheatGui) {
        cheatGui.Hide()
    }
}
#HotIf