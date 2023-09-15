---
ospool:
    path: software_examples/python/tutorial-ScalingUp-Python/README.md
---

# Scaling Up With HTCondor’s Queue Command

Many large scale computations require the ability to process multiple jobs concurrently. Consider the extensive
sampling done for a multi-dimensional Monte Carlo integration, parameter sweep for a given model or molecular
dynamics simulation with several initial conditions. These calculations require 
submitting many jobs. About a million CPU hours per day are available to OSG users
on an opportunistic basis. Learning how to scale up and control large
numbers of jobs is essential to realize the full potential of distributed high
throughput computing on the OSG.

![fig 1](https://raw.githubusercontent.com/OSGConnect/tutorial-ScalingUp-Python/master/Images/Slide1.png)

The  HTCondor's `queue` command can run multiple jobs from a single job description file. In this tutorial, we will see how to scale up the calculations for a simple python example using the HTCondor’s queue command.

Once we understand the basic HTCondor script to run a single job, it is easy
to scale up.

To download the materials for this tutorial, use the command

<pre class="term"><code>$ git clone https://github.com/OSGConnect/tutorial-ScalingUp-Python</code></pre>

Inside the `tutorial-ScalingUp-python` directory, all the required files are available. This includes the sample python program, job description file and executable files.  
Move into the directory with

<pre class="term"><code>$ cd tutorial-ScalingUp-Python</code></pre>

## Python script and the optimization function

Let us take a look at our objective function that we are trying to optimize.

	f = (1 - x)**2 + (y - x**2)**2

This a two dimensional Rosenbrock function. Clearly, the minimum is located at (1,1). 
The Rosenbrock function is one of the test functions used to test the robustness of an optimization method.

<!-- 
The figure previously used shows a minimum at (0,0), is symmetric, and has f(0,3) ~ 900, suggesting that equation used was actually
		f = x**2 + 100(y - x**2)**2
![fig 2](https://raw.githubusercontent.com/OSGConnect/tutorial-ScalingUp-Python/master/Images/RosenBrockFunction.png)

The actual figure should look something like this:
https://www.wolframalpha.com/input?i=plot+f%28x%2Cy%29+%3D+%281-x%29**2+%2B+%28y-x**2%29**2+for+x+from+-2+to+2+and+for+y+from+-1+to+3
-->

Here, we are going to use the brute force optimization approach to evaluate the two dimensional Rosenbrock function on grids of points. 
The boundary values for the grid points are randomly assigned inside the python script. However, these default values may be replaced by 
user supplied values.

To run the calculations with the random boundary values, the script is executed without any argument:

<pre class="term"><code>python3 rosen_brock_brute_opt.py</code></pre>
    
To run the calculations with the user supplied values, the script is executed with input arguments:

    python3 rosen_brock_brute_opt.py x_low x_high y_low y_high

where x_low and x_high are low and high values along x direction, and y_low and y_high are the low and high values along the y direction.

For example, the boundary of x direction is (-3, 3) and the boundary of y direction is (-2, 3).

<pre class="term"><code>python3 rosen_brock_brute_opt.py  -3 3 -2 2</code></pre>
    
sets the boundary of x direction to (-3, 3) and the boundary of y direction to (-2, 3).

The directory `Example1` runs the python script with the default random values. The directories `Example2`, and `Example3` deal with supplying the boundary values as input arguments. 

The python script requires the SciPy package, which is typically not included in standard installations of Python 3. 
Therefore, we will use a container that has Python 3 and SciPy installed. 
If you'd like to test the script, you can do so with

<pre class="term"><code>apptainer shell /cvmfs/singularity.opensciencegrid.org/htc/rocky:8</code></pre>

and then run one of the above commands.

<!-- 
## Execution Script

Let us take a look at the execution script, `scalingup-python-wrapper.sh`

    #!/bin/bash

    python3 ./rosen_brock_brute_opt.py  $1 $2 $3 $4

This will execute the python script `rosen_brock_brute_opt.py`. The python script takes four argument but they are optional. If we don't supply these optional arguments, the values are internally assigned.
-->

## Submitting Jobs Concurrently

![fig 3](https://raw.githubusercontent.com/OSGConnect/tutorial-ScalingUp-Python/master/Images/Slide2.png)

Now let us take a look at job description file. 

<pre class="term"><code>cd Example1
cat ScalingUp-PythonCals.submit</code></pre>

If we want to submit several jobs, we need to track log, out and error  files for each job. An easy way to do this is to add the `$(Cluster)` and `$(Process)` variables to the file names. You can see this below in the names given to the standard output, standard 
error and HTCondor log files: 

<pre class="sub"><code>executable = ../rosen_brock_brute_opt.py

log = Log/job.$(Cluster).$(Process).log
output = Log/job.$(Cluster).$(Process).out
error = Log/job.$(Cluster).$(Process).err

+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/htc/rocky:8"

request_cpus = 1
request_memory = 1 GB
request_disk = 1 GB

queue 10</code></pre>

Note the `queue 10`.  This tells Condor to queue 10 copies of this job as one cluster. 

Let us submit the above job

<pre class="term"><code>$ condor_submit ScalingUp-PythonCals.submit
Submitting job(s)..........
10 job(s) submitted to cluster 329837.</code></pre>

Apply your `condor_q` knowledge to see this job progress. After all 
jobs finished, execute the `post_script.sh`  script to sort the results. 

<pre class="term"><code>./post_script.sh</code></pre>

Note that all ten jobs will have run with random arguments because we did not supply 
any from the submit file. What if we wanted to supply those arguments so that we could 
reproduce this analysis if needed? The next example shows how to do this. 

## Providing Different Inputs to Jobs

In the previous example, we did not pass 
any argument to the program and the program generated random boundary conditions.  If we have some guess about what could be a better boundary condition, it is a good idea to supply the boundary 
condition as arguments. 

It is possible to use a single file to supply multiple arguments. We can take the job description file from the previous example, and modify it to include arguments. The modified job description file is available in the `Example2` directory. Take a look at the job description file `ScalingUp-PythonCals.submit`. 

<pre class="term"><code>$ cd ../Example2
$ cat ScalingUp-PythonCals.submit</code></pre>

<pre class="sub"><code>executable = ../rosen_brock_brute_opt.py
arguments = $(x_low) $(x_high) $(y_low) $(y_high)

log = Log/job.$(Cluster).$(Process).log
output = Log/job.$(Cluster).$(Process).out
error = Log/job.$(Cluster).$(Process).err

+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/htc/rocky:8"

request_cpus = 1
request_memory = 1 GB
request_disk = 1 GB

queue x_low x_high y_low y_high from job_values.txt</code></pre>

A major part of the job description file looks same as the previous example. The main 
difference is the addition of  `arguments` keyword, which looks like this: 

<pre class="sub"><code>arguments = $(x_low) $(x_high) $(y_low) $(y_high)</code></pre>

The given arguments `$(x_low)`, `$(x_high)`, etc. are actually variables that represent
the values we want to use. These values are set in the queue command at the end of the 
file: 

<pre class="sub"><code>queue x_low x_high y_low y_high from job_values.txt</code></pre>

Take a look at job_values.txt: 

<pre class="term"><code>$ cat job_values.txt</code></pre>

<pre class="file"><code>-9 9 -9 9
-8 8 -8 8
-7 7 -7 7
-6 6 -6 6
-5 5 -5 5
-4 4 -4 4
-3 3 -3 3
-2 2 -2 2
-1 1 -1 1</code></pre>

The submit file's `queue` statement will read in this file and assign each value in 
a row to the four variables shown in the `queue` statement. Each row corresponds to the 
submission of a unique job with those four values. 
 
Let us submit the above job to see this: 

<pre class="term"><code>$ condor_submit ScalingUp-PythonCals.submit
Submitting job(s)..........
9 job(s) submitted to cluster 329840.</code></pre>

Apply your `condor_q` knowledge to see this job progress. After all 
jobs finished, execute the `post_script.sh`  script to sort the results. 

<pre class="term"><code>./post_process.sh</code></pre>

## Another Example of Different Inputs

In the previous example, we split the input information into four variables 
that were included in the `arguments` line. However, we could have set the 
`arguments` line directly, without intermediate values. This is shown in 
Example 3: 

<pre class="term"><code>$ cd ../Example3
$ cat ScalingUp-PythonCals.submit</code></pre>

<pre class="sub"><code>executable = ../rosen_brock_brute_opt.py

log = Log/job.$(Cluster).$(Process).log
output = Log/job.$(Cluster).$(Process).out
error = Log/job.$(Cluster).$(Process).err

+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/htc/rocky:8"

request_cpus = 1
request_memory = 1 GB
request_disk = 1 GB

queue arguments from job_values.txt</code></pre>

Here, `arguments` has disappeared from the top of the file because we've included 
it in the queue statement at the end. The `job_values.txt` file has the same values 
as before; in this syntax, HTCondor will submit a job for each row of values and the 
job's arguments will be those four values. 

Let us submit the above job

<pre class="term"><code>$ condor_submit ScalingUp-PythonCals.submit
Submitting job(s)..........
9 job(s) submitted to cluster 329839.</code></pre>

Apply your `condor_q` and `connect watch` knowledge to see this job progress. After all 
jobs finished, execute the `post_script.sh`  script to sort the results. 

    ./post_process.sh
