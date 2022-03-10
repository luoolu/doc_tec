## 一键提取，在浏览器控制台Console输入并回车即可


var SSRs=[];
$$('table>tbody>tr').forEach(function(tr){
SSRs.push(tr.children[0].children[0].getAttribute("data"));
});
console.log(SSRs.join("\n"))
