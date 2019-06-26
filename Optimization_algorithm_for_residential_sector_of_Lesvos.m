%x = sdpvar(1,4);
%objective = x(1)*x(4)*[x(1)+x(2)+x(3)]+x(3);
%constraints = [x(1)*x(2)*x(3)*x(4)>=25, x(1)*x(1)+x(2)*x(2)+x(3)*x(3)+x(4)*x(4)==40,1<=x<=5];
%optimize(constraints,objective,sdpsettings('solver','CPLEX'));
%y=value(x);
%z=value(objective);


%===============
Lesvos_Houses= 'C:/Users/Dimitres/Desktop/Διπλωματικη/load shifting/Μονοκατοικια_syskeues_lesvou.xlsx'
feb2 = xlsread(Lesvos_Houses,2,'K2:O25');
LoadL=feb2(:,1);
PriceL=feb2(:,3);
FlexLoadL = xlsread(Lesvos_Houses,2,'C2:E25');
FlexibilityL=FlexLoadL(:,3);

%Ylopoiisi antikeimenikis synartisis Obj1=========================== 
EtotL=sum(LoadL);
for n=1:24
    Obj1L(n)=EtotL/24;
end


%======Ylopoiisi antikeimenikis synartisis Obj2=========================== 
PriceAVGL = sum(PriceL)/24;
PriceMAXL = max(PriceL);

Total_LoadL=0;
for n=1:24
    Total_LoadL=Total_LoadL+LoadL(n);
end

for n=1:24
    %Obj2L(n)=(PriceAVGL/PriceL(n))*LoadL(n);
    Obj2L(n)=(PriceAVGL/PriceL(n))* Total_LoadL/24;
    %Obj2L(n)=(PriceAVGL/PriceMAXL)*(1/PriceL(n))* Total_LoadL;
end



%====Dianysma me ta flexible fortia analoga me tin wra leitourgias tous 
PshiftedL = zeros(24,1);%arxikopoiisi tou dianysmatos PshiftedL

for  i= 1:24
    for j=1:length(FlexLoadL)
        
       if i== FlexLoadL(j,1);
       PshiftedL(i)=FlexLoadL(j,2)+PshiftedL(i);  
       end
       
   end
end

%===Dinysma Pfixed

PfixedL = feb2(:,1)-PshiftedL;
PL = FlexLoadL(:,2);

%===========dimioyrgia binary pinaka a[i;j]=========
for  j= 1:length(PL)
   for i = 1:24
       
       if i== FlexLoadL(j,1);
       aL(i,j)= 1;
       else aL(i,j)= 0;
       end
       
   end
end

%=============
PloadL = PfixedL + aL*PL;

%===========Optimization problem=========================
qL= binvar(24,length(FlexLoadL));
objective=0;
for t=1:24   

  
    %objective =objective + sum((Pload(t)-Obj1(t))^2);
    objective =objective + sum((PfixedL(t) + sum(qL(t,:)*PL(:))-Obj2L(t))^2);
end

%==========constraints===============
constraintsL = [];
for  j= 1:length(PL)
    
    t_lowerL = FlexLoadL(j,1)-FlexibilityL(j);
    t_higherL =FlexLoadL(j,1)+FlexibilityL(j);
    
       if t_lowerL < 0%%%%%
        t_lowerL=24+t_lowerL;
        
        for t = t_higherL+1:t_lowerL-1
       
            constraintsL=[constraintsL,qL(t,j) == 0];
        end
        
       elseif t_higherL > 24%%%%%%
           t_higherL=t_higherL-24;
             
           for t = t_higherL+1:t_lowerL-1
       
             constraintsL=[constraintsL,qL(t,j) == 0];
            
           end
           
           else
               for t = 1:t_lowerL-1%%%%%%
       
                    constraintsL=[constraintsL,qL(t,j) == 0];
               end
               
               for t = t_higherL+1:24
       
                    constraintsL=[constraintsL,qL(t,j) == 0];
               end
       end
       
end

for j = 1:length(PL)
    
     constraintsL=[constraintsL,sum(qL(:,j)) ==sum(aL(:,j)) ];
end
%constraints = [ Pfixed +q*P >= 0];


%===========Yalmip optimize toolbox================================
optimize(constraintsL,objective,sdpsettings('solver','CPLEX'));

yL=value(qL);
zL=value(objective);

%x=1:24;
PloadShift = PfixedL + yL*PL;

%===========Shifted schedule-apothikeuei se ena dianysma tis nees wres leitourgias twn syskeuwn================================
for  j= 1:length(PL)
   for i = 1:24
       
       if yL(i,j)==1
       ShiftedFlexLoadL(j)= i;
       end
       
   end
end

%===================Plotting a Gantt Chart========= 
[~,DevicesNamesL]  = xlsread(Lesvos_Houses,2,'B2:B19');

for j= 1:length(PL)

    hL(j,1:2)=[FlexLoadL(j,1),1];
    if ShiftedFlexLoadL(j)== 24
        kL(j,1:2)=[0,1];
    else
    kL(j,1:2)=[ShiftedFlexLoadL(j),1];
    end
end
close all
figure('position', [328   140   720   443]);
HL = barh(1:length(PL), hL,0.4,'blue','stacked');
set(HL([1]),'Visible','off');
set(gca,'yTickLabel',DevicesNamesL,'yTick',1:1:17);
set(gca,'xTick',0:1:24);

hold on

GL = barh( kL,0.4,'red','stacked');
set(GL([1]),'Visible','off');
legend([HL(1),GL(1)],'Initial Schedule', 'Shifted Schedule','Location','northwest');
xlabel('Time(h)');
hold off
box off
grid on
grid minor
shg

%=======load shifting sti synoliki kampyli tis lesvou(line graph)
figure('position', [328   140   720   443]);
x=1:1:24; 
LesvosTotal=feb2(:,5);
load1L=LesvosTotal;
Rest_Consumption=feb2(:,2)+feb2(:,4);
load2L=PfixedL + yL*PL+Rest_Consumption;
plot(x,load1L,x,load2L,'LineWidth',2);
xlabel('Time(h)');
ylabel('Electric power consumption(kW)');
legend('Initial load curve','Shifted load curve','Location','northwest');
box off;
grid on
grid minor
set(gca,'xTick',0:1:24);

%===========Apotelesmata se grafikes=========================
%plot(x,Pload1,x,Obj1);

%===line graphs-kampyli fortiou prin kai meta====
figure('position', [328   140   720   443]);
load1L=PfixedL + yL*PL;
load2L=PfixedL + aL*PL;
plot(x,load1L,x,load2L,'LineWidth',2);
xlabel('Time(h)');
ylabel('Electric power consumption(kW)');
legend('Shifted load curve','Initial load curve','Location','northwest');
box off;
grid on
grid minor
set(gca,'xTick',0:1:24);

%===bar grafiki me metatopismeno fotrio====
figure('position', [328   140   720   443]);
x=1:1:24; 

bar(x, [PfixedL yL*PL], 0.5, 'stack')
set(gca,'xTick',0:1:24);

hold on
plot(Obj2L,'r');
xlabel('Time(h)');
ylabel('Electric power consumption(kW)');
legend('Pfixed', 'Pflexible','Objective 1','Location','northwest')
box off;
grid on
grid minor
hold off
%plot(x,Price),title('Hourly Energy Prices'),xlabel('Time(h)'),ylabel('Price (xrimatikes monades/kWh)')

%======bar graph-arxiki kampyli me to flexible kai stathero fortio
figure('position', [328   140   720   443]); %249 85 856 327
x=1:1:24; 

bar(x, [PfixedL aL*PL], 0.5, 'stack');
hold on
plot(Obj2L,'r');
xlabel('Time(h)');
ylabel('Electric power consumption(kW)');
set(gca,'xTick',0:1:24);
legend('Pfixed','Pflexible(1000 houses)','Objective 1','Location','northwest');
box off;
grid on
grid minor
%========real time pricing graph=======
figure('position', [362   235   614   288]);
ylim([0 6]);
x=1:1:24;
stairs(PriceL,'red','LineWidth',1.2);
xlabel('Time(h)');
ylabel('Cents/kWh');
set(gca,'xTick',0:1:24);
legend('Real-time Pricing','Location','northwest');
ylim([0.8*min(PriceL) max(PriceL)*1.1]);
box off;
grid on
grid minor

Pinakas_aL= 'C:\Users\Dimitres\Desktop\pinakas_aL.xlsx';


%=================Deiktes axiologisis============================
%======================Periptwsi Objective 1==========================================

%====Residential sector=========
LoadL96=interp1(1:24, LoadL, 1:0.25:24);
PloadShift96=interp1(1:24, PloadShift, 1:0.25:24);

[ideal_line,LE_baseLine,LE_loadShift,LE_baseLine2,LE_loadShift2,RHP_baseline,RHP_loadShift,d1,d2,HPD1,HPD2] = deiktes(LoadL96,PloadShift96);
LE=['LE   ',num2str(LE_baseLine),'         ',num2str(LE_loadShift) ]; 
LE2=['LE^2 ',num2str(LE_baseLine2),'       ',num2str(LE_loadShift2) ]; 
RHP=['RHP   ',num2str(RHP_baseline),'         ',num2str(RHP_loadShift) ];
D=['d        ',num2str(d1),'            ',num2str(d2) ];
HPD=['HPD   ',num2str(HPD1),'         ',num2str(HPD2) ];
display('     Baseline      Shifted Line');
disp(LE);disp(LE2);disp(RHP);disp(D);disp(HPD);


%===Total Lesvos
x1=interp1(1:24, LesvosTotal, 1:0.25:24);
x2=interp1(1:24, PfixedL + yL*PL+Rest_Consumption, 1:0.25:24);

[ideal_line,LE_baseLine,LE_loadShift,LE_baseLine2,LE_loadShift2,RHP_baseline,RHP_loadShift,d1,d2,HPD1,HPD2] = deiktes(x1,x2);
LE=['LE   ',num2str(LE_baseLine),'         ',num2str(LE_loadShift) ]; 
LE2=['LE^2 ',num2str(LE_baseLine2),'       ',num2str(LE_loadShift2) ]; 
RHP=['RHP   ',num2str(RHP_baseline),'         ',num2str(RHP_loadShift) ];
D=['d        ',num2str(d1),'            ',num2str(d2) ];
HPD=['HPD   ',num2str(HPD1),'         ',num2str(HPD2) ];
display('     Baseline      Shifted Line');
disp(LE);disp(LE2);disp(RHP);disp(D);disp(HPD);


xlswrite(Pinakas_aL,aL);
%get(gcf,'position');