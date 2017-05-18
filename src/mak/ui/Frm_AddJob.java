/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package mak.ui;

import mak.tools.StringUtil;

/**
 *
 * @author Chin
 */
public class Frm_AddJob extends javax.swing.JDialog {
    public int ModalResult = -1;
    public String ConStrSrc;
    public String ConStrDst;
    public String CfgStr;
    
    public boolean singleMode = false;

    /**
     * Creates new form Frm_AddJob
     */
    public Frm_AddJob() {
        initComponents();
        ClearEdit();
    }
    
    public void ClearEdit(){
        edt_name.setText("");
        edt_dst.setText("");
        edt_src.setText("");
        edt_bkPnt.setText("");
    }
    
    public void displaytTodit(){
        edt_src.setText(DisPlayText(ConStrSrc));
        edt_dst.setText(DisPlayText(ConStrDst));
        
        edt_name.setText(StringUtil.getXmlValueFromStr(CfgStr, ConstString.JobName));
        edt_bkPnt.setText(StringUtil.getXmlValueFromStr(CfgStr, ConstString.StartTime));
    }
    
    private void getCfgStr(){
        StringBuilder sbsb = new StringBuilder();
        sbsb.append("<");
        sbsb.append(ConstString.JobName);
        sbsb.append(">");
        sbsb.append(edt_name.getText());
        sbsb.append("</");
        sbsb.append(ConstString.JobName);
        sbsb.append(">");
        
        sbsb.append("<");
        sbsb.append(ConstString.StartTime);
        sbsb.append(">");
        sbsb.append(edt_bkPnt.getText());
        sbsb.append("</");
        sbsb.append(ConstString.StartTime);
        sbsb.append(">");
        CfgStr = sbsb.toString();
    }

    @Override
    public void setVisible(boolean dd){
    	if (dd) {
    		displaytTodit();
		}
    	super.setVisible(dd);
    }
    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jPopupMenu1 = new javax.swing.JPopupMenu();
        jMenuItem1 = new javax.swing.JMenuItem();
        jMenuItem2 = new javax.swing.JMenuItem();
        jMenuItem3 = new javax.swing.JMenuItem();
        jLabel1 = new javax.swing.JLabel();
        edt_name = new javax.swing.JTextField();
        jLabel2 = new javax.swing.JLabel();
        jLabel3 = new javax.swing.JLabel();
        jLabel4 = new javax.swing.JLabel();
        edt_src = new javax.swing.JTextField();
        edt_dst = new javax.swing.JTextField();
        edt_bkPnt = new javax.swing.JTextField();
        btn_src = new javax.swing.JButton();
        btn_dst = new javax.swing.JButton();
        jButton3 = new javax.swing.JButton();
        jButton4 = new javax.swing.JButton();

        jMenuItem1.setText("数据库");
        jMenuItem1.setToolTipText("");
        jMenuItem1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jMenuItem1ActionPerformed(evt);
            }
        });
        jPopupMenu1.add(jMenuItem1);

        jMenuItem2.setText("MQ");
        jMenuItem2.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jMenuItem2ActionPerformed(evt);
            }
        });
        jPopupMenu1.add(jMenuItem2);

        jMenuItem3.setText("Text");
        jMenuItem3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jMenuItem3ActionPerformed(evt);
            }
        });
        jPopupMenu1.add(jMenuItem3);

        setResizable(false);
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowActivated(java.awt.event.WindowEvent evt) {
                formWindowActivated(evt);
            }
        });

        jLabel1.setText("任务名称");
        jLabel1.setToolTipText("");

        edt_name.setText("jTextField1");

        jLabel2.setText("数据源");
        jLabel2.setToolTipText("");

        jLabel3.setText("数据目标");
        jLabel3.setToolTipText("");

        jLabel4.setText("捕获起点");
        jLabel4.setToolTipText("");

        edt_src.setText("jTextField2");

        edt_dst.setText("jTextField3");

        edt_bkPnt.setText("jTextField4");

        btn_src.setIcon(new javax.swing.ImageIcon(getClass().getResource("/mak/res/etl.png"))); // NOI18N
        btn_src.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                btn_srcActionPerformed(evt);
            }
        });

        btn_dst.setIcon(new javax.swing.ImageIcon(getClass().getResource("/mak/res/etl.png"))); // NOI18N
        btn_dst.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                btn_dstActionPerformed(evt);
            }
        });

        jButton3.setText("确定");
        jButton3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton3ActionPerformed(evt);
            }
        });

        jButton4.setText("关闭");
        jButton4.setToolTipText("");
        jButton4.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton4ActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(26, 26, 26)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jLabel1)
                    .addComponent(jLabel2)
                    .addComponent(jLabel3)
                    .addComponent(jLabel4))
                .addGap(18, 18, 18)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addGap(8, 8, 8)
                        .addComponent(jButton3, javax.swing.GroupLayout.PREFERRED_SIZE, 77, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addGap(58, 58, 58)
                        .addComponent(jButton4, javax.swing.GroupLayout.PREFERRED_SIZE, 77, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING, false)
                            .addComponent(edt_bkPnt, javax.swing.GroupLayout.DEFAULT_SIZE, 261, Short.MAX_VALUE)
                            .addComponent(edt_dst)
                            .addComponent(edt_src)
                            .addComponent(edt_name))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(btn_src, javax.swing.GroupLayout.PREFERRED_SIZE, 31, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(btn_dst, javax.swing.GroupLayout.PREFERRED_SIZE, 31, javax.swing.GroupLayout.PREFERRED_SIZE))))
                .addContainerGap(14, Short.MAX_VALUE))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(15, 15, 15)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(edt_name, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addGap(18, 18, 18)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(jLabel2)
                            .addComponent(edt_src, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(btn_src))
                        .addGap(18, 18, 18)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(jLabel3)
                            .addComponent(edt_dst, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)))
                    .addComponent(btn_dst))
                .addGap(18, 18, 18)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel4)
                    .addComponent(edt_bkPnt, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addGap(18, 18, 18)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButton3)
                    .addComponent(jButton4))
                .addContainerGap(39, Short.MAX_VALUE))
        );

        pack();
        setLocationRelativeTo(null);
    }// </editor-fold>//GEN-END:initComponents

    public String DisPlayText(String aConnStr) {
        StringBuilder sb = new StringBuilder();
        sb.append("DB@");
        sb.append(StringUtil.getXmlValueFromStr(aConnStr, "subtype"));
        sb.append("#");
        sb.append(StringUtil.getXmlValueFromStr(aConnStr, "host"));
        sb.append("$");
        sb.append(StringUtil.getXmlValueFromStr(aConnStr, "usrId"));
        sb.append("%");
        sb.append(StringUtil.getXmlValueFromStr(aConnStr, "dbName"));
        return sb.toString();
    }

    private void jMenuItem2ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jMenuItem2ActionPerformed

    }//GEN-LAST:event_jMenuItem2ActionPerformed

    private void jMenuItem1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jMenuItem1ActionPerformed
        if (jPopupMenu1.getInvoker().equals(btn_src)) {
            Frm_setDBConn frm = new Frm_setDBConn();
            frm.setModal(true);
            frm.SetConStr(ConStrSrc);
            frm.setVisible(true);

            if (frm.ModalResult == 1) {
                ConStrSrc = frm.ConnStr;
                edt_src.setText(DisPlayText(ConStrSrc));
            }
        } else {
            Frm_setDBConn frm = new Frm_setDBConn();
            frm.setModal(true);
            frm.SetConStr(ConStrDst);
            frm.setVisible(true);

            if (frm.ModalResult == 1) {
                ConStrDst = frm.ConnStr;
                edt_dst.setText(DisPlayText(ConStrDst));
            }
        }
    }//GEN-LAST:event_jMenuItem1ActionPerformed

    private void btn_dstActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_btn_dstActionPerformed
        jPopupMenu1.show(btn_dst, 0, 0);
    }//GEN-LAST:event_btn_dstActionPerformed

    private void jMenuItem3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jMenuItem3ActionPerformed
        if (jPopupMenu1.getInvoker().equals(btn_src)) {
            Frm_SetDBConnText frm = new Frm_SetDBConnText();
            frm.setModal(true);
            frm.setConStr(ConStrSrc);
            frm.setVisible(true);
            if (frm.ModalResult == 1) {
                ConStrSrc = frm.getConStr();
                edt_src.setText(DisPlayText(ConStrSrc));
            }
        } else {
            Frm_SetDBConnText frm = new Frm_SetDBConnText();
            frm.setModal(true);
            frm.setConStr(ConStrDst);
            frm.setVisible(true);
            if (frm.ModalResult == 1) {
                ConStrDst = frm.getConStr();
                edt_dst.setText(DisPlayText(ConStrDst));
            }
        }
    }//GEN-LAST:event_jMenuItem3ActionPerformed

    private void btn_srcActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_btn_srcActionPerformed
        jPopupMenu1.show(btn_src, 0, 0);
    }//GEN-LAST:event_btn_srcActionPerformed

    private void jButton3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton3ActionPerformed
        this.ModalResult = 1;
        getCfgStr();
        this.setVisible(false);
    }//GEN-LAST:event_jButton3ActionPerformed

    private void jButton4ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton4ActionPerformed
        this.setVisible(false);
    }//GEN-LAST:event_jButton4ActionPerformed

    private void formWindowActivated(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowActivated
        if (singleMode) {
            jMenuItem2.setVisible(false);
        }
    }//GEN-LAST:event_formWindowActivated


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton btn_dst;
    private javax.swing.JButton btn_src;
    private javax.swing.JTextField edt_bkPnt;
    private javax.swing.JTextField edt_dst;
    private javax.swing.JTextField edt_name;
    private javax.swing.JTextField edt_src;
    private javax.swing.JButton jButton3;
    private javax.swing.JButton jButton4;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JMenuItem jMenuItem1;
    private javax.swing.JMenuItem jMenuItem2;
    private javax.swing.JMenuItem jMenuItem3;
    private javax.swing.JPopupMenu jPopupMenu1;
    // End of variables declaration//GEN-END:variables
}
