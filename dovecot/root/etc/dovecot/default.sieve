require ["fileinto", "copy"];

# rule:[spam]
if anyof (header :is "X-Spam" "Yes")
{
    fileinto "Spam";
}
# rule:[archive]
elsif anyof (true)
{
    fileinto :copy "Archive";
}
