## What is this

This demo directory will show the capabilities of Terraform Static File Analysis with Mondoo

## Assumptions

* Where you're running this off of has a agent key with Mondoo setup that doesn't have to be specified
* The policy "Terraform Static Analysis Policy for AWS (Early Access)" is enabled in your Mondoo space. 

## How to run

1. Run `git checkout master`. 
2. Switch to a git branch called `begin-tfs3-demo`, for example `git checkout remotes/origin/begin-tfs3-demo`. 
2. Inside this directory run `mondoo scan -t terraform --path`. 
3. Show output / tell story
4. Switch to the main git branch (e.g. master or main), for example `git checkout master`.
5. Inside this directory run `mondoo scan -t terraform --path`. 
6. Show output / tell story.

## Warnings

- The code being checked cannot be used in a Terraform plan. 
    - Reason 1: The log target bucket is a hard code piece of text, it will fail during plan
    - Reason 2: Even with Reason 1 fixed, the code does not adhere to `Amazon Web Services (AWS) Operational Best Practices For S3`. So it will really make your story not work.
- Why does it not adhere to Best Practices: Because the Operations Best Practices requires every S3 resource to be logged, doing this with Terraform AWS v3, it creates a circular dependency. This is fixed with v4, but the Static File Analysis policy only supports up to v3. 

