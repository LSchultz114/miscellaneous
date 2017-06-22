from  subprocess import Popen, PIPE
import csv
import sys,os

def calibrationtest(x,dir):
# The julia script we use to evaluate this is located in a different directory then where this will be called from
    origWD = os.getcwd()
    juliascript_dir=os.path.split(dir)[0]
    os.chdir(juliascript_dir)
# Run the julia script via pipe and provide the output
    p1 = Popen(["julia fw1.jl " + ' '.join(map(str,x))], stdout=PIPE,  shell=True)
    output = p1.communicate()[0]
# Save the output into a results file in the appropraite format (matching spearmint_lite format)
    os.chdir(origWD)
    newline= ""
    newline = str(output) + " 0 " + ' '.join(map(str,x)) + "\n"
    outfile = open('results.dat','w')
    outfile.write(newline)
    outfile.close()

    return newline


if __name__ == '__main__':
    dir=sys.argv[0]
    x=sys.argv[1:]
    calibrationtest(x,dir)
