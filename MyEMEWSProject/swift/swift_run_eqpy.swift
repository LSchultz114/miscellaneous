import files;
import string;
import sys;
import io;
import stats;
import python;
import math;
import location;
import assert;
import R;

import EQPy;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");
string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
string r_ranks[] = split(resident_work_ranks,",");


string read_last_row = ----
  last.row<-readLines("%sresults.dat")
----;

app (file out, file err) run_model (string model_sh, string param_line, string instance)
{
   "bash" model_sh param_line emews_root instance @stdout=out @stderr=err;
}

(string result) get_result(string instance_dir) {
  // Use a few lines of R code to read the output file
  code = read_last_row % instance_dir;
  result = R(code,"paste(last.row,collapse=' ')");
}

(string result) run_obj(string param_line, string id_suffix)
{
    // make instance dir
    string instance_dir = "%s/instance_%s/" % (turbine_output, id_suffix);
    make_dir(instance_dir) => {
      file out <instance_dir + "out.txt">;
      file err <instance_dir + "err.txt">;
      string model_sh = emews_root + "/scripts/eqpy_CalibrationTest.sh";
      (out,err) = run_model(model_sh, param_line,instance_dir) =>
      result = get_result(instance_dir) =>
      // delete the instance directory as it is no longer needed
      // if it is needed then delete this line
      rm_dir(instance_dir);
    }
}

(string agg_result) obj(string params, string iter_indiv_id) {
      agg_result=run_obj(params, iter_indiv_id);
}

(void v) loop (location ME, int ME_rank) {
    for (boolean b = true, int i = 1;
       b;
       b=c, i = i + 1)
  {
    // gets the model parameters from the python algorithm
    string params =  EQPy_get(ME);
    boolean c;
    // when the python algorithm is finished it should
    // pass "DONE" into the queue, and then the
    // expected from code: pass "DONE" and a multi-line output
    if (params == "DONE")
    {
        string finals =  EQPy_get(ME);
        
     //   multi_line_finals = join(split(finals, ";"), "\\n");
     //   string fname = "%s/final_result_%i" % (turbine_output, ME_rank);
     //   file results_file <fname> = write(multi_line_finals) =>
     //   printf("Writing final result to %s", fname) =>
     //   printf("Results: %s", multi_line_finals) =>
	printf(finals) =>
        v = make_void() =>
        c = false;
    }
    else if (params == "EQPY_ABORT")
    {
        printf("EQPy Aborted");
        string why = EQPy_get(ME);
        printf("%s", why) =>
        v = propagate() =>
        c = false;
    }
    else
    {
        string param_array[] = split(params, ";");
        string fresult[];
        foreach index,element in param_array
         {
            fresult[element] = obj(index, "%i_%i_%i" % (ME_rank,i,element));
         }
        string res = join(fresult, ";");
        EQPy_put(ME,"'%s'" % res) => c = true;

    }
  }
}

(void o) start (int ME_rank, int num_trials, int num_points) {
    location ME = locationFromRank(ME_rank);
    algo_params = "%d,%d" % (num_trials,num_points);
    EQPy_init_package(ME,"emews_spearmint") =>
    EQPy_get(ME) =>
    EQPy_put(ME,"'%s'" % algo_params) =>
      loop(ME, ME_rank) => {
        EQPy_stop(ME);
        o = propagate();
    }
}

// deletes the specified directory
app (void o) rm_dir(string dirname) {
  "rm" "-rf" dirname;
}

// call this to create any required directories
app (void o) make_dir(string dirname) {
  "mkdir" "-p" dirname;
}



main() {

  int num_trials = toint(argv("nt", "2"));
  int num_points = toint(argv("np", "3"));

  // PYTHONPATH needs to be set for python code to be run
  assert(strlen(getenv("PYTHONPATH")) > 0, "Set PYTHONPATH!");
  assert(strlen(emews_root) > 0, "Set EMEWS_PROJECT_ROOT!");

  int ME_ranks[];
  foreach r_rank, i in r_ranks{
    ME_ranks[i] = toint(r_rank);
  }

    foreach ME_rank, i in ME_ranks {
      start(ME_rank, num_trials, num_points) =>
      printf("End rank: %d", ME_rank);
    }

}
