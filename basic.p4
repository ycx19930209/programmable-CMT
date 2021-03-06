/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
register< bit<32> >(256) count;
//set the threshold of the polling
register< bit<32> >(4)   threshold;
//read the standard_metadata fileds
register< bit<32> >(3)  enq_timestamp;
register< bit<19> >(3)  enq_qdepth;
register< bit<32> >(3)  deq_timedelta;
register< bit<19> >(3)  deq_qdepth;
/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}
header tcp_t {
    bit<16> srcport;
    bit<16> dstport;
    bit<32> sequence;
    bit<32> ackseq;
    bit<4>  headerlength;
    bit<6>  reservation;
    bit<1>  URG;
    bit<1>  ACK;
    bit<1>  PSH;
    bit<1>  RST;
    bit<1>  SYN;
    bit<1>  FIN;
    bit<16> windowsize;
    bit<16> checksum;
    bit<16> pointer;
}
struct metadata {
    bit<8>  hashcode;
    bit<9>  tempport;
    bit<32> tempcount;
    bit<32> threshold1;
    bit<32> threshold2;
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
		6: parse_tcp;
		_: accept;
	}
    }
    state parse_tcp {
	packet.extract(hdr.tcp);
	transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action myhash(ip4Addr_t srcAddr,ip4Addr_t dstAddr,bit<8> protocol,bit<16> srcport,bit<16> dstport){
	meta.hashcode = srcAddr[7:0]+srcAddr[7:0]+protocol+srcport[12:5]+dstport[12:5];
    }
    action threshold_path1(){
        threshold.read(meta.threshold1,(bit<32>)0);
        threshold.read(meta.threshold2,(bit<32>)1);
        
    }
    action threshold_path2(){
        threshold.read(meta.threshold1,(bit<32>)2);
        threshold.read(meta.threshold2,(bit<32>)3);
      
    }
    action drop() {
        mark_to_drop();
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
   table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }
    
    table ipv4_lpm1 {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }
    table ipv4_lpm2 {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }
    table ipv4_lpm3 {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }
    

    action do_read_count() {
	count.read(meta.tempcount,(bit<32>)meta.hashcode);
    }

    apply {
	if (standard_metadata.ingress_port == 1&&hdr.ipv4.isValid()){
            myhash(hdr.ipv4.srcAddr,hdr.ipv4.dstAddr,hdr.ipv4.protocol,hdr.tcp.srcport,hdr.tcp.dstport);
	    do_read_count();
	    if(meta.hashcode < 128){
                threshold_path1();
                if(meta.tempcount < meta.threshold1){
                    meta.tempport = 1;
                    //ipv4_lpm1.apply();
		    count.write((bit<32>)meta.hashcode,meta.tempcount+1);
                }
		else{
                    meta.tempport = 2;
                    //ipv4_lpm2.apply();
		    count.write((bit<32>)meta.hashcode,meta.tempcount+1);
                }
	
                if(meta.tempcount >= meta.threshold2-1){
                    count.write((bit<32>)meta.hashcode,(bit<32>)0);
                }
	    }
	    else{
		threshold_path2();
                if(meta.tempcount < meta.threshold1){
                    meta.tempport = 2;
                    //ipv4_lpm2.apply();
		    count.write((bit<32>)meta.hashcode,meta.tempcount+1);
                }
		else{
                    meta.tempport = 3;
                    //ipv4_lpm3.apply();
		    count.write((bit<32>)meta.hashcode,meta.tempcount+1);
                }
                if(meta.tempcount >= meta.threshold2-1){
                    count.write((bit<32>)meta.hashcode,(bit<32>)0);
                }
	    }
            if(meta.tempport == 1){
		ipv4_lpm1.apply();
            }
            else{
                ipv4_lpm2.apply();
            }
	}else{
	    ipv4_lpm.apply();
	}
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
     action write_fileds(bit<32> prt){
	enq_timestamp.write(prt,standard_metadata.enq_timestamp);
	enq_qdepth.write(prt,standard_metadata.enq_qdepth);
	deq_timedelta.write(prt,standard_metadata.deq_timedelta);
	deq_qdepth.write(prt,standard_metadata.deq_qdepth);
    }
    apply {
	if(standard_metadata.egress_port ==2) {
		write_fileds((bit<32>)0);
	}
	if(standard_metadata.egress_port ==3) {
		write_fileds((bit<32>)1);
	}
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
