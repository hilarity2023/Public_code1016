F_max=50;
% %% 输出轴，范围4~18阶，分成3部分，生成4~8根阶次线
% n=40;
% ratio_error=0.95;
% 
% for j=1:n
%     feature=0.12;
%     lim=50;
%     h=0.01;
%     F=0:h:lim;
%     F=F';
%     a1=floor(floor((14*rand(1)+4)/feature)*feature*100)/100;
%     b1=floor(5*sqrt(rand(1))+3.5);
% 
%     if rand(1)<0.2
%         a2=floor(floor((4*rand(1)+9)/feature)*feature*100)/100;
%         b2=floor(4*sqrt(rand(1))+3);
%         b=b1+b2;
% 
%         x_peaks=zeros(b,1);
%         y_peaks=zeros(b,1);
%         for i=1:b1
%             c=0.05*rand(1)+0.975;
%             x_peaks(i)=a1+(i-2)*feature+feature*c;
%             y_peaks(i)=15*rand(1)+25;
% 
%         end
%         for i=b1+1:b1+b2
%             c=0.05*rand(1)+0.975;
%             x_peaks(i)=a2+(i-2)*feature+feature*c;
%             y_peaks(i)=15*rand(1)+25;
% 
%         end
% 
%     else
%         b=b1;
%         x_peaks=zeros(b,1);
%         y_peaks=zeros(b,1);
%         for i=1:b
%             c=0.05*rand(1)+0.975;
%             x_peaks(i)=a1+(i-2)*feature+feature*c;
%             y_peaks(i)=15*rand(1)+25;
% 
%         end
%     end
% 
% 
%     if rand(1)<ratio_error
% 
%         if b<14
%             d=6*(rand(1)-0.5);
%             if d<0
%                 x_peaks(b+1)=a1-d;
%                 y_peaks(b+1)=15*rand(1)+25;
%             else
%                 x_peaks(b+1)=x_peaks(b)+d;
%                 y_peaks(b+1)=15*rand(1)+25;
%             end
% 
%             if rand(1)<0.7
%                 d=6*(rand(1)-0.5);
%                 if d<0
%                     x_peaks(b+2)=a1-d;
%                     y_peaks(b+2)=15*rand(1)+25;
%                 else
%                     x_peaks(b+2)=x_peaks(b)+d;
%                     y_peaks(b+2)=15*rand(1)+25;
%                 end
%             end
% 
%             if rand(1)<0.7
%                 d=round((b-1)*rand(1)+0.5);
%                 y_peaks(d,d+1)=0;
%             end
% 
%         elseif b>14
%             d=round((b-1)*rand(1)+0.5);
%             y_peaks(d)=0;
%             if rand(1)<0.7
%                 d=round((b-1)*rand(1)+0.5);
%                 y_peaks(d,d+1)=0;
%             end
%             if rand(1)<0.7
%                 d=round((b-1)*rand(1)+0.5);
%                 y_peaks(d,d+1)=0;
%             end
% 
%         end
% 
% 
%     end
%     if rand(1)<0.7
%         d=round((b-1)*rand(1)+0.5);
%         y_peaks(d,d+1)=0;
%     end
%     if rand(1)<0.7
%         d=round((b-1)*rand(1)+0.5);
%         y_peaks(d,d+1)=0;
%     end
% 
%     k=find(x_peaks<lim);
%     x_peaks=x_peaks(k);
%     y_peaks=y_peaks(k);
% 
% 
%     baseline = 0; % 基线值
%     width = 0.1; % 每个峰值点的宽度
% 
%     % 定义 x 范围
%     x = F; % x 的范围可以根据需要调整
% 
%     % 生成三角形峰
%     y = baseline;
%     for i = 1:length(x_peaks)
%         y = y + (y_peaks(i) - baseline) * max(1 - abs((x - x_peaks(i)) / (width*0.5*(rand(1)+0.5) / 2)), 0);
%     end
%     % % 绘图
%     % figure
%     % plot(x, y);
%     % xlabel('x');
%     % ylabel('y');
%     % title('Generated Multiple Triangular Peaks');
%     % grid on;
% 
% 
%     T=1:0.1:10;
%     P= repmat(y, 1, length(T));
% 
%     fig = figure('Visible', 'off','Position', [300, 100, 1400, 600]);
%     % fig = figure;
%     surf(F, T, P', 'EdgeColor', 'none');
%     axis tight;
%     view(0, 90);  % 从上方查看
%     %ylim([0,max(T)])
%     xlim([0,lim])
% 
%     % xlabel('阶次');
%     % ylabel('Time (s)');
%     set(gca,'YTick',[])
%     xticks(linspace(0, lim, 11));
%     % xticklabels(x_ticks);
%     set(gca, 'XTickLabelRotation', 0);
%     %title(name, 'Interpreter', 'none');
%     clim([0, 40]);  % 设置颜色映射范围
%     %colorbar;
%     colormap(gray);  % 使用彩色映射
%     shading interp;       % 平滑颜色过渡，使阶次线更清晰
%     grid on;
% 
%     folderPath='E:\test\shaft_out';
%     name=num2str(j);
%     savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
%     exportgraphics(fig, savePath, 'Resolution', 300); % 保存为 jpg 文件，分辨率 600 DPI
%     % 关闭当前图形窗口
%     close(fig);
% 
% end



% 
% %% Spline shaft，范围3~13阶，生成3~10根阶次线
% 
% for j=1:n
%     feature=1;
%     lim=50;
%     h=0.01;
%     F=0:h:lim;
%     F=F';
%     a=floor(10*rand(1)+3);
%     b=round(7*sqrt(rand(1))+2.5);
%     x_peaks=zeros(b,1);
%     y_peaks=zeros(b,1);
%     for i=1:b
%         c=0.05*rand(1)+0.975;
%         x_peaks(i)=a+(i-2)*feature+feature*c;
%         y_peaks(i)=15*rand(1)+25;
%     end
% 
%     if rand(1)<ratio_error
% 
%         if b<5
%             d=10*(rand(1)-0.5);
%             if d<0
%                 x_peaks(b+1)=a-d;
%                 y_peaks(b+1)=15*rand(1)+25;
%             else
%                 x_peaks(b+1)=x_peaks(b)+d;
%                 y_peaks(b+1)=15*rand(1)+25;
%             end
% 
%             if rand(1)<0.7
%                 d=10*(rand(1)-0.5);
%                 if d<0
%                     x_peaks(b+2)=a-d;
%                     y_peaks(b+2)=15*rand(1)+25;
%                 else
%                     x_peaks(b+2)=x_peaks(b)+d;
%                     y_peaks(b+2)=15*rand(1)+25;
%                 end
%             end
% 
%         elseif b>6
%             d=round(4*rand(1)+3);
%             y_peaks(d)=0;
%             if rand(1)<0.7
%                 d=round(4*rand(1)+3);
%                 y_peaks(d)=0;
%             end
% 
%         end
% 
%     end
% 
%     k=find(x_peaks<lim);
%     x_peaks=x_peaks(k);
%     y_peaks=y_peaks(k);
% 
% 
%     baseline = 0; % 基线值
%     width = 0.3; % 每个峰值点的宽度
% 
%     % 定义 x 范围
%     x = F; % x 的范围可以根据需要调整
% 
%     % 生成三角形峰
%     y = baseline;
%     for i = 1:length(x_peaks)
%         y = y + (y_peaks(i) - baseline) * max(1 - abs((x - x_peaks(i)) / (width*(rand(1)+0.5) / 2)), 0);
%     end
%     % % 绘图
%     % figure
%     % plot(x, y);
%     % xlabel('x');
%     % ylabel('y');
%     % title('Generated Multiple Triangular Peaks');
%     % grid on;
% 
% 
%     T=1:0.1:10;
%     P= repmat(y, 1, length(T));
% % 
% %     fig = figure('Visible', 'off','Position', [300, 100, 1400, 600]);
% %     % fig = figure;
% %     surf(F, T, P', 'EdgeColor', 'none');
% %     axis tight;
% %     view(0, 90);  % 从上方查看
% %     %ylim([0,max(T)])
% %     xlim([0,lim])
% % 
% %     % xlabel('阶次');
% %     % ylabel('Time (s)');
% %     set(gca,'YTick',[])
% %     xticks(linspace(0, lim, 11));
% %     % xticklabels(x_ticks);
% %     set(gca, 'XTickLabelRotation', 0);
% %     %title(name, 'Interpreter', 'none');
% %     clim([0, 40]);  % 设置颜色映射范围
% %     %colorbar;
% %     colormap(gray);  % 使用彩色映射
% %     shading interp;       % 平滑颜色过渡，使阶次线更清晰
% %     grid on;
% % 
% % 
% %     folderPath='E:\dudu';
% %     name=num2str(j);
% %     savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
% %     exportgraphics(fig, savePath, 'Resolution', 300); % 保存为 jpg 文件，分辨率 600 DPI
% %     % 关闭当前图形窗口
% %     close(fig);
% %% 论文绘图
% width_cm  = 7.8;
% height_cm = 3.6;
% wps_dpi   = 96;                 % WPS 默认读取 DPI
% pxPerCm   = wps_dpi / 2.54;
% widthPx   = round(width_cm  * pxPerCm);  % ≈ 294 px
% heightPx  = round(height_cm * pxPerCm);  % ≈ 136 px
% 
% 
% fig = figure('Visible','off','Units','pixels','Position',[0 0 widthPx heightPx]);
% 
% 
% surf(F,T,P','EdgeColor','none');
% axis tight; view(0,90);
% % ylim([0 max(T)]); xlim([0 F_max]);
% clim([0 35]); colormap jet; shading interp;
% set(gca,'FontName','Times New Roman','FontSize',7);
% xlabel('Orders','FontName','Times New Roman','FontSize',7);
% ylabel('Time/s','FontName','Times New Roman','FontSize',7);
% set(gca,'XTickLabelRotation',0);
% xticks(linspace(0, F_max, F_max/5+1));
% 
% folderPath='E:\dudu';
% name=num2str(j);
% 
% savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
% exportgraphics(fig, savePath, 'Resolution', 600);  % 保存为 jpg 文件，分辨率 600 DPI
% 
% % savePath2 = fullfile(folderPath, [name,'_dwt', '.fig']);  % 保存路径
% % savefig(fig, savePath2, 'compact') 
% 
%     % 关闭当前图形窗口
%     close(fig);
% end
% 
% 
% %% 二级齿轮，范围11.56阶，生成1~2根阶次线
% 
% ratio_error=0.4;
% 
% for j=1:n
%     feature=11.56;
%     lim=50;
%     h=0.01;
%     F=0:h:lim;
%     F=F';
%     a=11.56;
%     b=round(2*sqrt(rand(1))+0.5);
% 
%     x_peaks=zeros(b,1);
%     y_peaks=zeros(b,1);
%     for i=1:b
%         c=0.005*rand(1)+0.9975;
%         x_peaks(i)=a+(i-2)*feature+feature*c;
%         y_peaks(i)=15*rand(1)+25;
% 
%     end
% 
% 
%     if rand(1)<ratio_error
% 
%         c=round(2*sqrt(rand(1))+0.5);
%         for i=b+1:b+c
%             x_peaks(i)=floor(9*rand(1)+1);
%             y_peaks(i)=15*rand(1)+25;
% 
%         end
% 
%     end
% 
%     k=find(x_peaks<lim);
%     x_peaks=x_peaks(k);
%     y_peaks=y_peaks(k);
% 
% 
%     baseline = 0; % 基线值
%     width = 0.6; % 每个峰值点的宽度
% 
%     % 定义 x 范围
%     x = F; % x 的范围可以根据需要调整
% 
%     % 生成三角形峰
%     y = baseline;
%     for i = 1:length(x_peaks)
%         y = y + (y_peaks(i) - baseline) * max(1 - abs((x - x_peaks(i)) / (width*(rand(1)+0.5) / 4)), 0);
%     end
%     % % 绘图
%     % figure
%     % plot(x, y);
%     % xlabel('x');
%     % ylabel('y');
%     % title('Generated Multiple Triangular Peaks');
%     % grid on;
% 
% 
%     T=1:0.1:10;
%     P= repmat(y, 1, length(T));
% 
% %     fig = figure('Visible', 'off','Position', [300, 100, 1400, 600]);
% %     % fig = figure;
% %     surf(F, T, P', 'EdgeColor', 'none');
% %     axis tight;
% %     view(0, 90);  % 从上方查看
% %     %ylim([0,max(T)])
% %     xlim([0,lim])
% % 
% %     % xlabel('阶次');
% %     % ylabel('Time (s)');
% %     set(gca,'YTick',[])
% %     xticks(linspace(0, lim, 11));
% %     % xticklabels(x_ticks);
% %     set(gca, 'XTickLabelRotation', 0);
% %     %title(name, 'Interpreter', 'none');
% %     clim([0, 40]);  % 设置颜色映射范围
% %     %colorbar;
% %     colormap(gray);  % 使用彩色映射
% %     shading interp;       % 平滑颜色过渡，使阶次线更清晰
% %     grid on;
% % 
% %     folderPath='E:\2nd gears';
% %     name=num2str(j);
% %     savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
% %     exportgraphics(fig, savePath, 'Resolution', 300); % 保存为 jpg 文件，分辨率 600 DPI
% %     % 关闭当前图形窗口
% %     close(fig);
% %% 论文绘图
% width_cm  = 7.8;
% height_cm = 3.6;
% wps_dpi   = 96;                 % WPS 默认读取 DPI
% pxPerCm   = wps_dpi / 2.54;
% widthPx   = round(width_cm  * pxPerCm);  % ≈ 294 px
% heightPx  = round(height_cm * pxPerCm);  % ≈ 136 px
% 
% 
% fig = figure('Visible','off','Units','pixels','Position',[0 0 widthPx heightPx]);
% 
% 
% surf(F,T,P','EdgeColor','none');
% axis tight; view(0,90);
% % ylim([0 max(T)]); xlim([0 F_max]);
% clim([0 35]); colormap jet; shading interp;
% set(gca,'FontName','Times New Roman','FontSize',7);
% xlabel('Orders','FontName','Times New Roman','FontSize',7);
% ylabel('Time/s','FontName','Times New Roman','FontSize',7);
% set(gca,'XTickLabelRotation',0);
% xticks(linspace(0, F_max, F_max/5+1));
% 
% folderPath='E:\2nd gears';
% name=num2str(j);
% 
% savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
% exportgraphics(fig, savePath, 'Resolution', 600);  % 保存为 jpg 文件，分辨率 600 DPI
% 
% % savePath2 = fullfile(folderPath, [name,'_dwt', '.fig']);  % 保存路径
% % savefig(fig, savePath2, 'compact') 
% 
%     % 关闭当前图形窗口
%     close(fig);
% end
% 
%% 轮毂轴承，范围2~12阶，生成3~7根阶次线
ratio_error=0.95;
n=50;
for j=1:n
    feature=0.8;
    lim=50;
    h=0.01;
    F=0:h:lim;
    F=F';
    a=floor(floor((10*rand(1)+2)/0.8)*0.8*100)/100;
    b=round(5*(rand(1))^2+2.5);

    x_peaks=zeros(b,1);
    y_peaks=zeros(b,1);
    for i=1:b
        c=0.05*rand(1)+0.975;
        x_peaks(i)=a+(i-2)*feature+feature*c;
        y_peaks(i)=15*rand(1)+25;

    end


    if rand(1)<ratio_error

        if b<5
            d=6*(rand(1)-0.5);
            if d<0
                x_peaks(b+1)=a-d;
                y_peaks(b+1)=15*rand(1)+25;
            else
                x_peaks(b+1)=x_peaks(b)+d;
                y_peaks(b+1)=15*rand(1)+25;
            end

            if rand(1)<0.7
                d=6*(rand(1)-0.5);
                if d<0
                    x_peaks(b+2)=a-d;
                    y_peaks(b+2)=15*rand(1)+25;
                else
                    x_peaks(b+2)=x_peaks(b)+d;
                    y_peaks(b+2)=15*rand(1)+25;
                end
            end

        elseif b>6
            d=round(4*rand(1)+3);
            y_peaks(d)=0;
            if rand(1)<0.7
                d=round(4*rand(1)+3);
                y_peaks(d)=0;
            end

        end

    end

    k=find(x_peaks<lim);
    x_peaks=x_peaks(k);
    y_peaks=y_peaks(k);


    baseline = 0; % 基线值
    width = 0.3; % 每个峰值点的宽度

    % 定义 x 范围
    x = F; % x 的范围可以根据需要调整

    % 生成三角形峰
    y = baseline;
    for i = 1:length(x_peaks)
        y = y + (y_peaks(i) - baseline) * max(1 - abs((x - x_peaks(i)) / (width*(rand(1)+0.5) / 2)), 0);
    end
    % % 绘图
    % figure
    % plot(x, y);
    % xlabel('x');
    % ylabel('y');
    % title('Generated Multiple Triangular Peaks');
    % grid on;


    T=1:0.1:10;
    P= repmat(y, 1, length(T));

    fig = figure('Visible', 'off','Position', [300, 100, 1400, 600]);
    % fig = figure;
    surf(F, T, P', 'EdgeColor', 'none');
    axis tight;
    view(0, 90);  % 从上方查看
    %ylim([0,max(T)])
    xlim([0,lim])

    % xlabel('阶次');
    % ylabel('Time (s)');
    set(gca,'YTick',[])
    xticks(linspace(0, lim, 11));
    % xticklabels(x_ticks);
    set(gca, 'XTickLabelRotation', 0);
    %title(name, 'Interpreter', 'none');
    clim([0, 40]);  % 设置颜色映射范围
    %colorbar;
    colormap(gray);  % 使用彩色映射
    shading interp;       % 平滑颜色过渡，使阶次线更清晰
    grid on;

    folderPath='E:\train\hub bearing';
    name=num2str(j);
    savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
    exportgraphics(fig, savePath, 'Resolution', 300); % 保存为 jpg 文件，分辨率 600 DPI
    % 关闭当前图形窗口
    close(fig);
% %% 论文绘图
% width_cm  = 7.8;
% height_cm = 3.6;
% wps_dpi   = 96;                 % WPS 默认读取 DPI
% pxPerCm   = wps_dpi / 2.54;
% widthPx   = round(width_cm  * pxPerCm);  % ≈ 294 px
% heightPx  = round(height_cm * pxPerCm);  % ≈ 136 px
% 
% 
% fig = figure('Visible','off','Units','pixels','Position',[0 0 widthPx heightPx]);
% 
% 
% surf(F,T,P','EdgeColor','none');
% axis tight; view(0,90);
% % ylim([0 max(T)]); xlim([0 F_max]);
% clim([0 35]); colormap jet; shading interp;
% set(gca,'FontName','Times New Roman','FontSize',7);
% xlabel('Orders','FontName','Times New Roman','FontSize',7);
% ylabel('Time/s','FontName','Times New Roman','FontSize',7);
% set(gca,'XTickLabelRotation',0);
% xticks(linspace(0, F_max, F_max/5+1));
% 
% folderPath='E:\hub bearing';
% name=num2str(j);
% 
% savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
% exportgraphics(fig, savePath, 'Resolution', 600);  % 保存为 jpg 文件，分辨率 600 DPI
% 
% % savePath2 = fullfile(folderPath, [name,'_dwt', '.fig']);  % 保存路径
% % savefig(fig, savePath2, 'compact') 
% 
%     % 关闭当前图形窗口
%     close(fig);
end


% %% 电机轴承2.57，范围15~50阶，生成3~6根阶次线
% n=50;
% ratio_error=0.75;
% 
% for j=1:n
%     feature=2.57;
%     lim=50;
%     h=0.01;
%     F=0:h:lim;
%     F=F';
%     a=floor(floor((10*rand(1)+15)/feature)*feature*100)/100;
%     b=round(3*sqrt(rand(1))+2.5);
% 
%     x_peaks=zeros(b,1);
%     y_peaks=zeros(b,1);
%     for i=1:b
%         c=0.05*rand(1)+0.975;
%         x_peaks(i)=a+(i-2)*feature+feature*c;
%         y_peaks(i)=15*rand(1)+25;
% 
%     end
% 
% 
%     if rand(1)<ratio_error
% 
%         if b<5
%             d=6*(rand(1)-0.5);
%             if d<0
%                 x_peaks(b+1)=a-d;
%                 y_peaks(b+1)=15*rand(1)+25;
%             else
%                 x_peaks(b+1)=x_peaks(b)+d;
%                 y_peaks(b+1)=15*rand(1)+25;
%             end
%         elseif b>6
%             d=round(1*rand(1)+4.5);
%             y_peaks(d)=0;
%         end
% 
%     end
% 
%     k=find(x_peaks<lim);
%     x_peaks=x_peaks(k);
%     y_peaks=y_peaks(k);
% 
% 
%     baseline = 0; % 基线值
%     width = 0.3; % 每个峰值点的宽度
% 
%     % 定义 x 范围
%     x = F; % x 的范围可以根据需要调整
% 
%     % 生成三角形峰
%     y = baseline;
%     for i = 1:length(x_peaks)
%         y = y + (y_peaks(i) - baseline) * max(1 - abs((x - x_peaks(i)) / (width*(rand(1)+0.5) / 2)), 0);
%     end
%     % % 绘图
%     % figure
%     % plot(x, y);
%     % xlabel('x');
%     % ylabel('y');
%     % title('Generated Multiple Triangular Peaks');
%     % grid on;
% 
% 
%     T=1:0.1:10;
%     P= repmat(y, 1, length(T));
% 
%     fig = figure('Visible', 'off','Position', [300, 100, 1400, 600]);
%     % fig = figure;
%     surf(F, T, P', 'EdgeColor', 'none');
%     axis tight;
%     view(0, 90);  % 从上方查看
%     %ylim([0,max(T)])
%     xlim([0,lim])
% 
%     % xlabel('阶次');
%     % ylabel('Time (s)');
%     set(gca,'YTick',[])
%     xticks(linspace(0, lim, 11));
%     % xticklabels(x_ticks);
%     set(gca, 'XTickLabelRotation', 0);
%     %title(name, 'Interpreter', 'none');
%     clim([0, 40]);  % 设置颜色映射范围
%     %colorbar;
%     colormap(gray);  % 使用彩色映射
%     shading interp;       % 平滑颜色过渡，使阶次线更清晰
%     grid on;
% 
%     folderPath='E:\train\motor bearing';
%     name=num2str(j);
%     savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
%     exportgraphics(fig, savePath, 'Resolution', 300); % 保存为 jpg 文件，分辨率 600 DPI
%     % 关闭当前图形窗口
%     close(fig);
% 
% % %% 论文绘图
% % width_cm  = 7.8;
% % height_cm = 3.6;
% % wps_dpi   = 96;                 % WPS 默认读取 DPI
% % pxPerCm   = wps_dpi / 2.54;
% % widthPx   = round(width_cm  * pxPerCm);  % ≈ 294 px
% % heightPx  = round(height_cm * pxPerCm);  % ≈ 136 px
% % 
% % 
% % fig = figure('Visible','off','Units','pixels','Position',[0 0 widthPx heightPx]);
% % 
% % 
% % surf(F,T,P','EdgeColor','none');
% % axis tight; view(0,90);
% % % ylim([0 max(T)]); xlim([0 F_max]);
% % clim([0 35]); colormap jet; shading interp;
% % set(gca,'FontName','Times New Roman','FontSize',7);
% % xlabel('Orders','FontName','Times New Roman','FontSize',7);
% % ylabel('Time/s','FontName','Times New Roman','FontSize',7);
% % set(gca,'XTickLabelRotation',0);
% % xticks(linspace(0, F_max, F_max/5+1));
% % 
% % folderPath='E:\train\motor bearing';
% % name=num2str(j);
% % 
% % savePath = fullfile(folderPath, [name, '.jpg']);  % 保存路径
% % exportgraphics(fig, savePath, 'Resolution', 600);  % 保存为 jpg 文件，分辨率 600 DPI
% % 
% % % savePath2 = fullfile(folderPath, [name,'_dwt', '.fig']);  % 保存路径
% % % savefig(fig, savePath2, 'compact') 
% % 
% %     % 关闭当前图形窗口
% %     close(fig);
% end