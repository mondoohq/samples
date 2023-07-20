# configure vhs
Set Shell bash
Set FontSize 16
Set Width 2400
Set Height 1400
Set PlaybackSpeed 2.0
Set Margin 20
Set MarginFill "#9147FF"
Set BorderRadius 10

# set output
Output aws-iam-mfa.gif
Output aws-iam-mfa.mp4

# load environment variables
Hide
Type "source .env"
Enter
Type "clear"
Enter
Sleep 1s
Show

# run commands
Type "cnspec scan aws --discover iam-users"
Sleep 500ms
Enter
Sleep 80s