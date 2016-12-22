require ["fileinto","copy"];

# rule:[spam]
if anyof (header :is "X-Spam-Flag" "yes")
{
    fileinto "Spam";
}
# rule:[archive]
elsif anyof (true)
{
    fileinto :copy "Archive";
}
