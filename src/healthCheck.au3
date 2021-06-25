#include <MsgBoxConstants.au3>
#include <FileConstants.au3.>

$firstTime = True
HotKeySet("!{ESC}", "Terminate")
HotKeySet("{PAUSE}", "TogglePause")

Global $Paused = False

$sFilePath = "config.ini"

;utf8 problem
$sData=FileRead($sFilePath)
$hFile=FileOpen($sFilePath, $FO_OVERWRITE+$FO_UNICODE )
FileWrite($hFile, $sData)
FileClose($hFile)

Global $mailFrom = IniRead($sFilePath, "mail", "from", "")
Global $mailTo = IniRead($sFilePath, "mail", "to", "")
Global $mailSubject = IniRead($sFilePath, "mail", "subject", "")
Global $mailSubjectAlarm = IniRead($sFilePath, "mail", "subject_alarm", "")
Global $mailSmtp = IniRead($sFilePath, "mail", "smtp", "")
Global $mailPriority = IniRead($sFilePath, "mail", "priority", "1")
Global $mailContentNoReaction = IniRead($sFilePath, "mail", "content_noreaction", "")
Global $mailContentCheckin = IniRead($sFilePath, "mail", "content_checkin", "")
Global $mailContentCheckout = IniRead($sFilePath, "mail", "content_checkout", "")

Global $messageQuestionAlive=IniRead($sFilePath, "messages", "question_alive", "")
Global $messageQuestionLastChance=IniRead($sFilePath, "messages", "question_last_chance", "")
Global $messageQuestionCheckin=IniRead($sFilePath, "messages", "question_checkin", "")
Global $messagePause=IniRead($sFilePath, "messages", "content_pause", "")
Global $messagePauseSubject=IniRead($sFilePath, "messages", "subject_pause", "")

Global $beepRepeat=IniRead($sFilePath, "beep", "repeat", "3")
Global $beepLength=IniRead($sFilePath, "beep", "length", "1000")
Global $beepFreq1=IniRead($sFilePath, "beep", "frequency_1", "500")
Global $beepFreq2=IniRead($sFilePath, "beep", "frequency_2", "1000")

Global $timerIntervalAlive=IniRead($sFilePath, "timer", "interval_alive", "60")
Global $timerIntervalNoReaction=IniRead($sFilePath, "timer", "interval_noreaction", "30")

while 1
   $question = $messageQuestionAlive
   if $firstTime Then
	  $question = $messageQuestionCheckin
	  $tmp = MsgBox(4, 'HealthCheck', $messageQuestionCheckin, Number($timerIntervalNoReaction) * 60) ; 6 yes, 7 no

	  Switch $tmp
	  Case 6
		 if $firstTime Then
			SendMail($mailContentCheckin, $mailSubject)
			$firstTime = False
		 EndIf
	  Case 7
		 $firstTime = False
	  EndSwitch
   Else
	  $tmp = MsgBox($MB_TOPMOST, 'HealthCheck', $question, Number($timerIntervalNoReaction) * 60) ; 6 yes, 7 no

	  if $tmp == -1 Then
		 For $i = 1 To Number($beepRepeat)
			Beep(Number($beepFreq1), Number($beepLength))
			Beep(Number($beepFreq2), Number($beepLength))
		 Next

		 $tmp = MsgBox($MB_TOPMOST, 'HealthCheck', $messageQuestionLastChance, Number($timerIntervalNoReaction) * 60)
		 if $tmp == -1 Then
			SendMail($mailContentNoReaction, $mailSubjectAlarm)
		 EndIf
	  EndIf
   EndIf
   Sleep(1000 * 60 * Number($timerIntervalAlive))
WEnd

Func SendMail($text, $subject)
   $hFile = FileOpen("body.txt", 2)
   FileWrite($hFile, $text)
   FileClose($hFile)

   ConsoleWrite("command")
   $command = '"' & @ScriptDir & '\blat3222\full\blat.exe" body.txt -server "' & $mailSmtp & '" -to "' & $mailTo & '" -cc "' & $mailFrom & '" -f "' & $mailFrom & '" -s "' & $subject & '" -priority ' & $mailPriority
   ConsoleWrite($command)
   Run($command, "", @SW_MINIMIZE)
EndFunc

Func TogglePause()
    $Paused = NOT $Paused
	ToolTip($messagePause, 0, 0, $messagePauseSubject, 2)
    While $Paused
		sleep(1000)
    WEnd
    ToolTip("")
EndFunc

Func Terminate()
   SendMail($mailContentCheckout, $mailSubject)
   Exit
EndFunc