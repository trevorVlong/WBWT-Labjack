function [done] = visplot(fig,plotnum,spm,spn,xl,yl,xlbl,ylbl,ttl,alfamat,cmat,dcj)
%visplot plots scatter data from 
%   Detailed explanation goes here

    figure(fig)
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
    cax = [0 9];
    subplot(spm,spn,plotnum);
    colormap('jet')
    for ii = 1:length(alfamat(1,:))
        %DCJ = Fdata(:,6,ii);
        DCJ = dcj(:,ii);
        %error check
%             size(alfamat(:,ii))
%             size(cmat(:,ii))
%             alfamat(:,ii)
%             cmat(:,ii)
        scatter(alfamat(:,ii)',cmat(:,ii)',20,DCJ,'filled');
        hold on
    end
    %plot options
        caxis(cax);
        grid on
        colorbar
        title(ttl)
        xlabel(xlbl)
        ylabel(ylbl)
        xlim(xl)
        ylim(yl)
        axis fill
    %axis square
    done = 1;
end

