# configure vhs
Set Shell bash
Set FontSize 16
Set Width 1200
Set Height 700
Set PlaybackSpeed 3.0
Set Margin 20
Set MarginFill "#9147FF"
Set BorderRadius 10

# set output
Output aws-ec2-instance.gif
Output aws-ec2-instance.mp4

# load environment variables
Hide
Type "source .env"
Enter
Type "clear"
Enter
Sleep 1s
Show

# run commands
Type "cnspec scan aws ec2 instance-connect ec2-user@i-08f694f3db223553f"
Sleep 500ms
Enter
Sleep 100s