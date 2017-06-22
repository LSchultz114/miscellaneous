using TrafficAssignment
using StatsBase
using MultivariateStats

# translate the input string from python into an Array
data_points= map(x->parse(Float64,x),ARGS)
#ta_frank_wolfe requires a ta_data structure. We will create a placeholder data structure based on Sioux Falls for our 'true' and 'noisy' tests
dt=load_ta_network("Sioux Falls")
dn=deepcopy(dt)
#replace first 8 array values in the noisy array with newly provided data points
for i in 1:8
	dn.travel_demand[1,i]=data_points[i]
	print
	end
#add noise
dn.travel_demand=round(dn.travel_demand.*(1+0.2+0.3.*randn(24,24)))
#run this through the ta_frank_wolfe program to get the travel time for the true and noisy
link_flow, link_travel_time, objective = ta_frank_wolfe(dt, log="on", tol=1e-3, step="newton")
link_flow1, link_travel_time1, objective1 = ta_frank_wolfe(dn, log="on", tol=1e-3, step="newton")
#we are interested in the avg difference of travel time of the first 8 pairs
s=[(link_travel_time[i]-link_travel_time1[i])^2 for i in 1:8]
y=sum(s)
print(y[1])
