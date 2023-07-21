# configure vhs
Set Shell bash
Set FontSize 16
Set Width 1200
Set Height 700
Set PlaybackSpeed 2.0
Set Margin 20
Set MarginFill "#9147FF"
Set BorderRadius 10

# set output
Output github-supply-chain.gif
Output github-supply-chain.mp4

# load environment variables
Hide
Type "source .env"
Enter
Type "clear"
Enter
Sleep 1s
Show

# run commands
Type "cnspec scan github org lunalectric --discover organization"
Sleep 500ms
Enter
Sleep 65s