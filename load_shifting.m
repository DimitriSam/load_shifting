%x = sdpvar(1,4);
%objective = x(1)*x(4)*[x(1)+x(2)+x(3)]+x(3);
%constraints = [x(1)*x(2)*x(3)*x(4)>=25, x(1)*x(1)+x(2)*x(2)+x(3)*x(3)+x(4)*x(4)==40,1<=x<=5];
%optimize(constraints,objective);
%y=value(x);
%z=value(objective);
%,sdpsettings('solver','gurobi')

%=====Diavasma arxeiwn apo file excel===========
Monokatoikia='C:/Users/Dimitres/Desktop/Project/data/Monokatoikia.xlsx'
Data = xlsread(Monokatoikia,'O2:R25');
FlexLoad=xlsread(Monokatoikia,'V2:X25');
Flexibility=FlexLoad(:,3);
Price = Data(:,1);
Load = Data(:,2);


%Ylopoiisi antikeimenikis synartisis Obj1=========================== 
PriceAVG = sum(Price)/24;
PriceMAX = max(Price);

Total_Load=0;
for n=1:24
    Total_Load=Total_Load+Load(n);
end

for n=1:24
    Obj1(n)=(PriceAVG/PriceMAX)*(1/Price(n))* Total_Load;
end

%Ylopoiisi antikeimenikis synartisis Obj2=========================== 
Etot=sum(Load);
for n=1:24
    Obj2(n)=Etot/24;
end

%==============Kathorismos twn staherwn kai twn eueliktwn fortiwn======================================
Pfixed = Data(:,4);
Pshifted = Data(:,3);
P = FlexLoad(:,2);

%===========dimioyrgia binary pinaka a[i;j]=========
for  j= 1:length(P)
   for i = 1:24
       
       if i== FlexLoad(j,1)+1;
       a(i,j)= 1;
       else a(i,j)= 0;
       end
       
   end
end

%=============
Pload = Pfixed + a*P;

%===========Optimization problem=========================
q= binvar(24,14);
objective=0;
for t=1:24   

  
    %objective =objective + sum((Pload(t)-Obj1(t))^2);
    objective =objective + sum((Pfixed(t) + sum(q(t,:)*P(:))-Obj1(t))^2);
end

%==========constraints===============
constraints = [];
for  j= 1:length(P)
    
    t_lower = FlexLoad(j,1)-Flexibility(j);
    t_higher =FlexLoad(j,1)+Flexibility(j);
    
       if t_lower < 0
        t_lower=24+t_lower;
        
        for t = t_higher+1:t_lower-1
       
            constraints=[constraints,q(t,j) == 0];
        end
        
       elseif t_higher > 24
           t_higher=t_higher-24;
             
           for t = t_higher+1:t_lower-1
       
             constraints=[constraints,q(t,j) == 0];
            
           end
           
           else
               for t = 1:t_lower-1
       
                    constraints=[constraints,q(t,j) == 0];
               end
               
               for t = t_higher+1:24
       
                    constraints=[constraints,q(t,j) == 0];
               end
       end
       
end

for j = 1:length(P)
    
     constraints=[constraints,sum(q(:,j)) ==sum(a(:,j)) ];
end
%constraints = [ Pfixed +q*P >= 0];


%===========Yalmip optimize toolbox================================
optimize(constraints,objective,sdpsettings('solver','CPLEX'));

y=value(q);
z=value(objective);

%x=1:24;
%Pload1 = Pfixed + y*P;

%===========Shifted schedule-apothikeuei se ena dianysma tis nees wres leitourgias twn syskeuwn================================
for  j= 1:length(P)
   for i = 1:24
       
       if y(i,j)==1
       ShiftedFlexLoad(j)= i;
       end
       
   end
end

%===================Plotting a Gantt Chart========= 
[~,DevicesNames]  = xlsread(Monokatoikia,'U2:U25');

for j= 1:length(P)

    h(j,1:2)=[FlexLoad(j,1),1];
    k(j,1:2)=[ShiftedFlexLoad(j),1];
    
end
close all
H = barh(1:14, h,0.4,'blue','stacked');
set(H([1]),'Visible','off');
set(gca,'yTickLabel',DevicesNames);
set(gca,'xTick',0:1:24);


hold on

G= barh( k,0.4,'red','stacked');
set(G([1]),'Visible','off');
legend('Initial Schedule', 'Shifted Schedule');

hold off
grid on
shg
%===========Apotelesmata se grafikes=========================
%plot(x,Pload1,x,Obj1);
%===bar grafiki me metatopismeno fotrio====
figure
x=1:1:24; 

bar(x, [Pfixed y*P], 0.5, 'stack')
set(gca,'xTick',0:1:24);

hold on
plot(Obj1)
title('Electric power consumption of 1000 houses'),xlabel('Time(h)'),ylabel('Electric power consumption')
legend('Pfixed', 'Pflexible','Obj1')
hold off
%plot(x,Price),title('Hourly Energy Prices'),xlabel('Time(h)'),ylabel('Price (xrimatikes monades/kWh)')

%===line graphs-kampyli fortiou prin kai meta====
figure
load1=Pfixed + y*P;
load2=Pfixed + a*P;
plot(x,load1,x,load2,'LineWidth',4);
title('Electric power consumption of 1000 houses'),xlabel('Time(h)'),ylabel('Electric power consumption')
legend('Initial load curve', 'Shifted load curve');
set(gca,'xTick',0:1:24);


%======bar graph-arxiki kampyli me to flexible kai stathero fortio
figure
x=1:1:24; 

bar(x, [Pfixed a*P], 0.5, 'stack')
title('Electric power consumption of 1000 houses'),xlabel('Time(h)'),ylabel('Electric power consumption')
set(gca,'xTick',0:1:24);