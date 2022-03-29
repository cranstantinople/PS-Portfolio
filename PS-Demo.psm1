Function Start-Demo {
    $Demo = @{}
    $Demo.Menu = @{}
    #MENU PROMPT
    $Demo.Menu.Prompt = "What Would You Like to Do?"
    #MENU OPTIONS
    $Demo.Menu.Options = [ordered]@{}
    #Option 1
    $Demo.Menu.Options.o1 = @{}
    $Demo.Menu.Options.o1.Name = "Play Wordi!"
    $Demo.Menu.Options.o1.Tip = "Popular Game, re-created using PowerShell"
    $Demo.Menu.Options.o1.Command = {
        Start-Wordi
    }
    #Option 2
    $Demo.Menu.Options.o2 = @{}
    $Demo.Menu.Options.o2.Name = "Point of Sale Troubleshooting Demo"
    $Demo.Menu.Options.o2.Tip = "Demo based on troubleshooting application I created for POS"
    $Demo.Menu.Options.o2.Command = {
        POS-Support
    }
    #Option 3
    $Demo.Menu.Options.o3 = @{}
    $Demo.Menu.Options.o3.Name = "View Script Repository"
    $Demo.Menu.Options.o3.Tip = "Opens my Portfolio Repository in GitHub to view all scripts I've created for repetative tasks"
    $Demo.Menu.Options.o3.Command = {
        Start-Process "https://github.com/cranstantinople/PS-Portfolio"
    }
    Clear-Host
    $Demo.Menu.Selection = Select-Options $Demo.Menu
    Invoke-Command $Demo.Menu.Selection.Command
    Start-Demo
}
Function Initialize-Wordi {
    #DEFAULT PREFERENCES
    $Global:Wordi = @{}
    $Wordi.Dictionary = @{}
    $Wordi.Dictionary.Type = "CSV"
    $Wordi.Dictionary.Location = @('https://www.claytsch.com/wordlist','C:\Demo\WordList.csv')
    #Game Options
    $Wordi.Options = @{}
    $Wordi.Options.WordLength = 5
    $Wordi.Options.Guesses = 6
    $Wordi.Options.Sleep = 500
    $Wordi.Options.TopWords = 1000
    $Wordi.Options.Colors = @{}  
    $Wordi.Options.Colors.None = @{}
    $Wordi.Options.Colors.None.Background = "White"
    $Wordi.Options.Colors.None.Foreground = "Black"
    $Wordi.Options.Colors.InWord = @{}
    $Wordi.Options.Colors.InWord.Background = "Yellow"
    $Wordi.Options.Colors.InWord.Foreground = "Black"
    $Wordi.Options.Colors.InPlace = @{}  
    $Wordi.Options.Colors.InPlace.Background = "Green"
    $Wordi.Options.Colors.InPlace.Foreground = "Black"
    $Wordi.Messages = @{}
    $Wordi.Messages.Welcome = "Welcome to Wordi!"
    $Wordi.Instructions = @{}
    #Demo game answer
    $Wordi.Instructions.Answer = @{}  
    $Wordi.Instructions.Answer.Word = "WORDI"
    $Wordi.Instructions.Guesses = @{}  
    $Wordi.Instructions.Guesses.Words = @('Guess','Sword','World','Wordi')
    $Wordi.Instructions.Command = {
        #Demo game
        $Wordi.Instructions.Answer.Letters = Get-WordLetters $Wordi.Instructions.Answer.Word -Answer
        $Wordi.Instructions.Guesses.All = [Ordered]@{}
        ForEach ($Guess in 1..$Wordi.Options.Guesses) {
            $Wordi.Instructions.Guesses.All."g$($Guess)" = @{}
            $Wordi.Instructions.Guesses.All."g$($Guess)".Number = $Guess
            $Wordi.Instructions.Guesses.All."g$($Guess)".Letters = Get-WordLetters
        }
        Clear-Host

        #Step 1
        Write-Host "--You get $($Wordi.Options.Guesses) tries to guess the secret word." -ForegroundColor Green
        ForEach ($Guess in $Wordi.Instructions.Guesses.All[0]) {
            $Guess.Word = $Wordi.Instructions.Guesses.Words[$Guess.Number-1].ToUpper()
            $Guess.Letters = Get-WordLetters $Guess.Word
            Compare-WordLetters -Answer $Wordi.Instructions.Answer
        }
        Write-Host
        Show-Guesses $Wordi.Instructions.Guesses.All -Wait 50
        Start-Sleep -Seconds 2
        Clear-Host

        #Step 2
        Write-Host "You get $($Wordi.Options.Guesses) tries to guess the secret word." -ForegroundColor Green
        Write-Host "--If a letter in your guess is in the answer, it will turn Yellow!" -ForegroundColor Yellow
        ForEach ($Guess in $Wordi.Instructions.Guesses.All[1]) {
            $Guess.Word = $Wordi.Instructions.Guesses.Words[$Guess.Number-1].ToUpper()
            $Guess.Letters = Get-WordLetters $Guess.Word
            Compare-WordLetters -Answer $Wordi.Instructions.Answer
        }
        Write-Host
        Show-Guesses $Wordi.Instructions.Guesses.All -Wait 50
        Start-Sleep -Seconds 2
        Clear-Host

        #Step 3
        Write-Host "You get $($Wordi.Options.Guesses) tries to guess the secret word." -ForegroundColor Green
        Write-Host "If a letter in your guess is in the answer, it will turn Yellow!" -ForegroundColor Yellow
        Write-Host "--If it's in the correct spot, it will turn Green!" -ForegroundColor Green
        ForEach ($Guess in $Wordi.Instructions.Guesses.All[2,3]) {
            $Guess.Word = $Wordi.Instructions.Guesses.Words[$Guess.Number-1].ToUpper()
            $Guess.Letters = Get-WordLetters $Guess.Word
            Compare-WordLetters -Answer $Wordi.Instructions.Answer
        }
        Write-Host
        Show-Guesses $Wordi.Instructions.Guesses.All -Wait 50
        Write-Host
    } 
}
Function Get-Dictionary {

    $Wordi.Dictionary.Menu = @{}
    #MENU PROMPT
    $Wordi.Dictionary.Menu.Prompt = "Where would you like to load it from?"
    #MENU OPTIONS
    $Wordi.Dictionary.Menu.Options = [ordered]@{}
    #Option 1
    $Wordi.Dictionary.Menu.Options.o1 = @{}
    $Wordi.Dictionary.Menu.Options.o1.Name = "Download from $($Wordi.Dictionary.Location[0])"
    $Wordi.Dictionary.Menu.Options.o1.Tip = "This takes a little longer, but this is a Demo after all."
    $Wordi.Dictionary.Menu.Options.o1.Command = {
        Write-Host "Retrieving Word List from $($Wordi.Dictionary.Location[0])" -ForegroundColor Yellow
        $Wordi.Dictionary.Import = Invoke-RestMethod $Wordi.Dictionary.Location[0]
    }
    #Option 2
    $Wordi.Dictionary.Menu.Options.o2 = @{}
    $Wordi.Dictionary.Menu.Options.o2.Name = "Import From Local CSV"
    $Wordi.Dictionary.Menu.Options.o2.Tip = "Only slightly faster, but just giving demo options."
    $Wordi.Dictionary.Menu.Options.o2.Command = {
        Write-Host "Retrieving Word List" -ForegroundColor Yellow
        $Wordi.Dictionary.Import = Get-Content $Wordi.Dictionary.Location[1] -Raw
    }

    #Menu Selection
    $Wordi.Dictionary.Menu.Selection = Select-Options $Wordi.Dictionary.Menu -Default 1 -Timeout 10
    #Run Selection
    Invoke-Command $Wordi.Dictionary.Menu.Selection.Command

    #Get All Words
    $Wordi.Dictionary.Words = @{}
    $Wordi.Dictionary.Words.All = If ($Wordi.Dictionary.Type = "CSV") {
        $Wordi.Dictionary.Import | ConvertFrom-Csv
    } Else {
        $Wordi.Dictionary.Import -replace @('{','}'),"" | ConvertFrom-Csv -Delimiter ":" -Header 'Word','Definition'
    }
    Write-Host "$($Wordi.Dictionary.Words.All.Count) Words Loaded..." -ForegroundColor Green

    #Get all words with correct number of letters.
    Write-Host "Getting all $($Wordi.Options.WordLength) Letter Words..." -ForegroundColor Yellow
    $Wordi.Dictionary.Words.Valid = $Wordi.Dictionary.Words.All | Where-Object {$_.Word.Length -eq $Wordi.Options.WordLength -and $_.Word -notmatch "-"}
    Write-Host "$($Wordi.Dictionary.Words.Valid.Count) $($Wordi.Options.WordLength) Letter Words Loaded..." -ForegroundColor Green
    
    #Get top words
    Write-Host "Getting Top $($Wordi.Options.TopWords) Words for Possible Answers..." -ForegroundColor Yellow
    $Wordi.Dictionary.Words.Top = $Wordi.Dictionary.Words.Valid | Sort-Object -Descending {[int]$_.Frequency} | Select-Object -First $Wordi.Options.TopWords

    Write-Host
    Write-Host "Word List Loaded!" -ForegroundColor Green
}
Function Get-WordLetters {
    
    #Parameters    
    param (
        $Word
    )

    #Get letters.
    ForEach ($Number in 1..$Wordi.Options.WordLength) {
        New-Object PSCustomObject -Property @{
            Number  = $Number
            Letter  = If ($Word) {$Word.ToCharArray()[$Number-1]} Else {" "}
            Status  = If ($Wordi.Game.Answer.Word -and $Word -eq $Wordi.Game.Answer.Word) {"InPlace"} Else {"None"}
        }
    }
}
Function Compare-WordLetters {

    #Parameters    
    param (
        $Answer
    )

    #Process letter matches.
    ForEach ($Letter in $Guess.Letters) {

        #Letter in place
        If ($Letter.Letter -eq $Answer.Letters[$Letter.Number-1].Letter) {
            $Letter.Status = "InPlace"
        } 
        #Letter in word         
        ElseIf ($Letter.Letter -in $Answer.Letters.Letter) {
            If (($Guess.Letters | Where-Object {$_.Letter -eq $Letter.Letter}).Count -le ($Answer.Letters | Where-Object {$_.Letter -eq $Letter.Letter}).Count) {
                $Letter.Status = "InWord"
            }
        }
    }
}
Function Start-Wordi {

    If (!$Wordi) {
        Initialize-Wordi
    }

    $Wordi.Menu = @{}

    #MENU PROMPT
    $Wordi.Menu.Prompt = "What Would You Like to Do?"
    
    #MENU OPTIONS
    $Wordi.Menu.Options = [ordered]@{}
    #Option 1
    $Wordi.Menu.Options.o1 = @{}
    $Wordi.Menu.Options.o1.Name = "Play Wordi!"
    $Wordi.Menu.Options.o1.Command = {
        New-Wordi
    }
    #Option 2
    $Wordi.Menu.Options.o2 = @{}
    $Wordi.Menu.Options.o2.Name = "Get Instructions"
    $Wordi.Menu.Options.o2.Command = {
        Clear-Host
        Invoke-Command $Wordi.Instructions.Command
        Select-Options -Continue AnyKey
        Start-Wordi
    }

    Clear-Host
    Write-Host $Wordi.Messages.Welcome -ForegroundColor Green
    $Wordi.Menu.Selection = Select-Options $Wordi.Menu
    Invoke-Command $Wordi.Menu.Selection.Command
}
Function Show-Guess {

    #Parameters 
    param (
        $Guess,
        $Wait
    )

    #Write each letter with background color corresponding to status.
    ForEach ($Letter in $Guess.Letters) {
        ForEach ($Color in $Wordi.Options.Colors) {
            $BackgroundColor = $Color.($Letter.Status).Background
            $ForegroundColor = $Color.($Letter.Status).Foreground
        }
        Write-Host $Letter.Letter -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor -NoNewline
        If ($Wait) {
            Start-Sleep -Milliseconds $Wait
        }
    }
    Write-Host
}
Function Show-Guesses {
    
    #Parameters 
    param (
        $Guesses,
        $Wait
    )

    #Show previous guesses
    ForEach ($EachGuess in $Guesses.Values) {
        Write-Host "$($EachGuess.Number). " -NoNewline
        If ($Wait) {
            Start-Sleep -Milliseconds $Wait
        }
        Show-Guess $EachGuess -Wait $Wait
    }
}
Function Test-Guess {
    
    #Parameters     
    param (
        $Answer
    )

    #Validate
    If ($Guess.Word -notin $Wordi.Dictionary.Words.Valid.Word) {
        #Invalid
        $Guess.Status = "Invalid"
        $Guess.Invalid += $Guess.Word
        #Message
        $Wordi.Game.Guesses.Message = $Wordi.Messages.Guesses.Invalid
        $Wordi.Game.Guesses.Message.Message = "$($Guess.Word.ToUpper()) Invalid.  Please Try Again."
    } Else {
        #Valid
        $Guess.Status = "Valid"
        #Get word letters
        $Guess.Letters = Get-WordLetters $Guess.Word
        Compare-WordLetters -Answer $Answer

        #MESSAGES
        #Default
        $Wordi.Game.Guesses.Message = $Wordi.Messages.Guesses.Default
        #No mathces
        If (($Guess.Letters.Status | Where-Object {$_ -eq "None"}).Count -eq $Wordi.Options.WordLength) {
            $Wordi.Game.Guesses.Message = $Wordi.Messages.Guesses.None
        }
        #More in word letters than previous guess
        If (($Guess.Letters.Status -eq "InWord").Count -gt ($Wordi.Game.Guesses.All[$Guess.Number-2].Letters.Status -eq "InWord").Count) {
            $Wordi.Game.Guesses.Message = $Wordi.Messages.Guesses.Better
        }
        #More in place letters than previous guess
        If (($Guess.Letters.Status -eq "InPlace").Count -gt ($Wordi.Game.Guesses.All[$Guess.Number-2].Letters.Status -eq "InPlace").Count) {
            $Wordi.Game.Guesses.Message = $Wordi.Messages.Guesses.Better
        }
        #If winner
        If (($Guess.Letters.Status -eq "InPlace").Count -eq $Wordi.Options.WordLength) {
            $Guess.Status = "Winner"
            $Wordi.Game.Guesses.Message = $Wordi.Messages.Guesses.Winner
        }
    }
}
Function New-Wordi {
    
    #Check if Wordi Variable exists
    If (!$Wordi) {
        Initialize-Wordi
    }
    $Wordi.Game = @{}
    $Wordi.Game.Options = @{} 
    $Wordi.Game.Answer = @{}
    $Wordi.Game.Guesses = @{} 
    $Wordi.Messages.Guesses = @{}
    $Wordi.Messages.Guesses.First = @{}
    $Wordi.Messages.Guesses.First.Message = "Make a guess!"
    $Wordi.Messages.Guesses.First.Color = "Green"
    $Wordi.Messages.Guesses.Default = @{}
    $Wordi.Messages.Guesses.Default.Message = "Keep tyring, you got this!"
    $Wordi.Messages.Guesses.Default.Color = "Yellow"
    $Wordi.Messages.Guesses.Invalid = @{}
    $Wordi.Messages.Guesses.Invalid.Message = "Invalid. Try again!"
    $Wordi.Messages.Guesses.Invalid.Color = "Red"
    $Wordi.Messages.Guesses.None = @{}
    $Wordi.Messages.Guesses.None.Message = "No Matches. Try again, you got this!"
    $Wordi.Messages.Guesses.None.Color = "Red"
    $Wordi.Messages.Guesses.Better = @{}
    $Wordi.Messages.Guesses.Better.Message = "Great job! Make another guess!"
    $Wordi.Messages.Guesses.Better.Color = "Green"
    $Wordi.Messages.Guesses.Winner = @{}
    $Wordi.Messages.Guesses.Winner.Message = "Winner!"
    $Wordi.Messages.Guesses.Winner.Color = "Green"
    $Wordi.Messages.Guesses.Winner.Console = "Green"
    $Wordi.Messages.Guesses.Lost = @{}
    $Wordi.Messages.Guesses.Lost.Message = "Nice Try!  Maybe Next Time."
    $Wordi.Messages.Guesses.Lost.Color = "Red"

    #Check if Dictionary exists
    If (!$Wordi.Dictionary.Words.All) {
        Write-Host
        Write-Host
        Write-Host "Need to Load Dictionary" -ForegroundColor Yellow
        Get-Dictionary
    } Else {
        Write-Host "Dictionary loaded!" -ForegroundColor Green
    }
    Select-Options -Continue AnyKey
    Clear-Host

    #Random word selector
    Write-Host "Selecting a Random Word..." -ForegroundColor Yellow
    $Wordi.Game.Options.Sleep = $Wordi.Options.Sleep
    While ($Wordi.Game.Options.Sleep -gt 2) {
        $Wordi.Game.Answer.Word = (Get-Random $Wordi.Dictionary.Words.Top).Word
        Write-Progress -Activity "Random Word Selector" -Status $Wordi.Game.Answer.Word.ToUpper()
        Start-Sleep -Milliseconds $Wordi.Game.Options.Sleep
        $Wordi.Game.Options.Sleep = $Wordi.Game.Options.Sleep*.90
    } 
    Write-Progress -Activity "Random Word Selector" -Completed
    
    #Select random word as answer
    $Wordi.Game.Answer.Word = (Get-Random $Wordi.Dictionary.Words.Top).Word.ToUpper()
    $Wordi.Game.Answer.Letters = Get-WordLetters $Wordi.Game.Answer.Word -Answer

    Clear-Host
    Write-Host "Random word selected... You'll never guess!" -ForegroundColor Green
    Write-Host
    Select-Options -Continue AnyKey
    Clear-Host
    
    #Generate guess placeholders
    $Wordi.Game.Guesses.All = [Ordered]@{}
    ForEach ($Guess in 1..$Wordi.Options.Guesses) {
        $Wordi.Game.Guesses.All."g$($Guess)" = @{}
        $Wordi.Game.Guesses.All."g$($Guess)".Number = $Guess
        $Wordi.Game.Guesses.All."g$($Guess)".Letters = Get-WordLetters
    }

    #Gameplay
    $Wordi.Game.Guesses.Message = $Wordi.Messages.Guesses.First
    ForEach ($Guess in $Wordi.Game.Guesses.All.Values)  {
        $Guess.Status = "New"
        #Wait for valid guess input
        While ($Guess.Status -notin @('Valid','Winner')) {
            Clear-Host
            Show-Guesses $Wordi.Game.Guesses.All
            #Message
            Write-Host $Wordi.Game.Guesses.Message.Message -ForegroundColor $Wordi.Game.Guesses.Message.Color
            $Guess.Word = (Read-Host "Guess $($Guess.Number)").ToUpper()
            Test-Guess -Answer $Wordi.Game.Answer
        }
        #Winner
        If ($Guess.Status -eq "Winner") {
            Show-Guesses $Wordi.Game.Guesses.All
            Write-Host $Wordi.Game.Guesses.Message.Message -ForegroundColor $Wordi.Game.Guesses.Message.Color
            Select-Options -Continue AnyKey
            Start-Wordi
        }
    }
    #Lost
    Clear-Host
    Show-Guesses $Wordi.Game.Guesses.All
    Write-Host $Wordi.Messages.Guesses.Lost.Text -ForegroundColor $Wordi.Messages.Guesses.Lost.Color
    Write-Host "The Correct Word was:"
    Show-Guess $Wordi.Game.Answer
    Select-Options -Continue AnyKey
    Start-Wordi
}