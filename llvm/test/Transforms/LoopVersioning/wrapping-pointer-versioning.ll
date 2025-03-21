; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -passes=loop-versioning -S < %s | FileCheck %s -check-prefix=LV

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"

; For this loop:
;   unsigned index = 0;
;   for (int i = 0; i < n; i++) {
;    A[2 * index] = A[2 * index] + B[i];
;    index++;
;   }
;
; SCEV is unable to prove that A[2 * i] does not overflow.
;
; Analyzing the IR does not help us because the GEPs are not
; affine AddRecExprs. However, we can turn them into AddRecExprs
; using SCEV Predicates.
;
; Once we have an affine expression we need to add an additional NUSW
; to check that the pointers don't wrap since the GEPs are not
; inbound.

; The expression for %mul_ext as analyzed by SCEV is
;    (zext i32 {0,+,2}<%for.body> to i64)
; We have added the nusw flag to turn this expression into the SCEV expression:
;    i64 {0,+,2}<%for.body>

define void @f1(ptr noalias %a,
; LV-LABEL: @f1(
; LV-NEXT:  for.body.lver.check:
; LV-NEXT:    [[TMP0:%.*]] = add i64 [[N:%.*]], -1
; LV-NEXT:    [[TMP1:%.*]] = icmp ugt i64 [[TMP0]], 4294967295
; LV-NEXT:    [[MUL1:%.*]] = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 4, i64 [[TMP0]])
; LV-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i64, i1 } [[MUL1]], 0
; LV-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i64, i1 } [[MUL1]], 1
; LV-NEXT:    [[TMP2:%.*]] = sub i64 0, [[MUL_RESULT]]
; LV-NEXT:    [[TMP3:%.*]] = getelementptr i8, ptr [[A:%.*]], i64 [[MUL_RESULT]]
; LV-NEXT:    [[TMP4:%.*]] = icmp ult ptr [[TMP3]], [[A]]
; LV-NEXT:    [[TMP6:%.*]] = or i1 [[TMP4]], [[MUL_OVERFLOW]]
; LV-NEXT:    [[TMP7:%.*]] = or i1 [[TMP1]], [[TMP6]]
; LV-NEXT:    br i1 [[TMP7]], label [[FOR_BODY_PH_LVER_ORIG:%.*]], label [[FOR_BODY_PH:%.*]]
; LV:       for.body.ph.lver.orig:
; LV-NEXT:    br label [[FOR_BODY_LVER_ORIG:%.*]]
; LV:       for.body.lver.orig:
; LV-NEXT:    [[IND_LVER_ORIG:%.*]] = phi i64 [ 0, [[FOR_BODY_PH_LVER_ORIG]] ], [ [[INC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[IND1_LVER_ORIG:%.*]] = phi i32 [ 0, [[FOR_BODY_PH_LVER_ORIG]] ], [ [[INC1_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[MUL_LVER_ORIG:%.*]] = mul i32 [[IND1_LVER_ORIG]], 2
; LV-NEXT:    [[MUL_EXT_LVER_ORIG:%.*]] = zext i32 [[MUL_LVER_ORIG]] to i64
; LV-NEXT:    [[ARRAYIDXA_LVER_ORIG:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT_LVER_ORIG]]
; LV-NEXT:    [[LOADA_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[ARRAYIDXB_LVER_ORIG:%.*]] = getelementptr i16, ptr [[B:%.*]], i64 [[IND_LVER_ORIG]]
; LV-NEXT:    [[LOADB_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXB_LVER_ORIG]], align 2
; LV-NEXT:    [[ADD_LVER_ORIG:%.*]] = mul i16 [[LOADA_LVER_ORIG]], [[LOADB_LVER_ORIG]]
; LV-NEXT:    store i16 [[ADD_LVER_ORIG]], ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[INC_LVER_ORIG]] = add nuw nsw i64 [[IND_LVER_ORIG]], 1
; LV-NEXT:    [[INC1_LVER_ORIG]] = add i32 [[IND1_LVER_ORIG]], 1
; LV-NEXT:    [[EXITCOND_LVER_ORIG:%.*]] = icmp eq i64 [[INC_LVER_ORIG]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND_LVER_ORIG]], label [[FOR_END_LOOPEXIT:%.*]], label [[FOR_BODY_LVER_ORIG]]
; LV:       for.body.ph:
; LV-NEXT:    br label [[FOR_BODY:%.*]]
; LV:       for.body:
; LV-NEXT:    [[IND:%.*]] = phi i64 [ 0, [[FOR_BODY_PH]] ], [ [[INC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[IND1:%.*]] = phi i32 [ 0, [[FOR_BODY_PH]] ], [ [[INC1:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[MUL:%.*]] = mul i32 [[IND1]], 2
; LV-NEXT:    [[MUL_EXT:%.*]] = zext i32 [[MUL]] to i64
; LV-NEXT:    [[ARRAYIDXA:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT]]
; LV-NEXT:    [[LOADA:%.*]] = load i16, ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[ARRAYIDXB:%.*]] = getelementptr i16, ptr [[B]], i64 [[IND]]
; LV-NEXT:    [[LOADB:%.*]] = load i16, ptr [[ARRAYIDXB]], align 2
; LV-NEXT:    [[ADD:%.*]] = mul i16 [[LOADA]], [[LOADB]]
; LV-NEXT:    store i16 [[ADD]], ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[INC]] = add nuw nsw i64 [[IND]], 1
; LV-NEXT:    [[INC1]] = add i32 [[IND1]], 1
; LV-NEXT:    [[EXITCOND:%.*]] = icmp eq i64 [[INC]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND]], label [[FOR_END_LOOPEXIT2:%.*]], label [[FOR_BODY]]
; LV:       for.end.loopexit:
; LV-NEXT:    br label [[FOR_END:%.*]]
; LV:       for.end.loopexit2:
; LV-NEXT:    br label [[FOR_END]]
; LV:       for.end:
; LV-NEXT:    ret void
;
  ptr noalias %b, i64 %N) {
entry:
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %ind = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %ind1 = phi i32 [ 0, %entry ], [ %inc1, %for.body ]

  %mul = mul i32 %ind1, 2
  %mul_ext = zext i32 %mul to i64

  %arrayidxA = getelementptr i16, ptr %a, i64 %mul_ext
  %loadA = load i16, ptr %arrayidxA, align 2

  %arrayidxB = getelementptr i16, ptr %b, i64 %ind
  %loadB = load i16, ptr %arrayidxB, align 2

  %add = mul i16 %loadA, %loadB

  store i16 %add, ptr %arrayidxA, align 2

  %inc = add nuw nsw i64 %ind, 1
  %inc1 = add i32 %ind1, 1

  %exitcond = icmp eq i64 %inc, %N
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

; For this loop:
;   unsigned index = n;
;   for (int i = 0; i < n; i++) {
;    A[2 * index] = A[2 * index] + B[i];
;    index--;
;   }
;
; the SCEV expression for 2 * index is not an AddRecExpr
; (and implictly not affine). However, we are able to make assumptions
; that will turn the expression into an affine one and continue the
; analysis.
;
; Once we have an affine expression we need to add an additional NUSW
; to check that the pointers don't wrap since the GEPs are not
; inbounds.
;
; This loop has a negative stride for A, and the nusw flag is required in
; order to properly extend the increment from i32 -4 to i64 -4.

; The expression for %mul_ext as analyzed by SCEV is
;     (zext i32 {(2 * (trunc i64 %N to i32)),+,-2}<%for.body> to i64)
; We have added the nusw flag to turn this expression into the following SCEV:
;     i64 {zext i32 (2 * (trunc i64 %N to i32)) to i64,+,-2}<%for.body>

define void @f2(ptr noalias %a,
; LV-LABEL: @f2(
; LV-NEXT:  for.body.lver.check:
; LV-NEXT:    [[TRUNCN:%.*]] = trunc i64 [[N:%.*]] to i32
; LV-NEXT:    [[TMP0:%.*]] = add i64 [[N]], -1
; LV-NEXT:    [[TMP1:%.*]] = shl i32 [[TRUNCN]], 1
; LV-NEXT:    [[TMP2:%.*]] = trunc i64 [[TMP0]] to i32
; LV-NEXT:    [[MUL1:%.*]] = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 2, i32 [[TMP2]])
; LV-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i32, i1 } [[MUL1]], 0
; LV-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i32, i1 } [[MUL1]], 1
; LV-NEXT:    [[TMP3:%.*]] = sub i32 [[TMP1]], [[MUL_RESULT]]
; LV-NEXT:    [[TMP4:%.*]] = icmp ugt i32 [[TMP3]], [[TMP1]]
; LV-NEXT:    [[TMP5:%.*]] = or i1 [[TMP4]], [[MUL_OVERFLOW]]
; LV-NEXT:    [[TMP6:%.*]] = icmp ugt i64 [[TMP0]], 4294967295
; LV-NEXT:    [[TMP7:%.*]] = or i1 [[TMP5]], [[TMP6]]
; LV-NEXT:    [[TMP8:%.*]] = trunc i64 [[N]] to i31
; LV-NEXT:    [[TMP9:%.*]] = zext i31 [[TMP8]] to i64
; LV-NEXT:    [[TMP10:%.*]] = shl nuw nsw i64 [[TMP9]], 2
; LV-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[A:%.*]], i64 [[TMP10]]
; LV-NEXT:    [[MUL2:%.*]] = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 4, i64 [[TMP0]])
; LV-NEXT:    [[MUL_RESULT3:%.*]] = extractvalue { i64, i1 } [[MUL2]], 0
; LV-NEXT:    [[MUL_OVERFLOW4:%.*]] = extractvalue { i64, i1 } [[MUL2]], 1
; LV-NEXT:    [[TMP11:%.*]] = sub i64 0, [[MUL_RESULT3]]
; LV-NEXT:    [[TMP12:%.*]] = getelementptr i8, ptr [[SCEVGEP]], i64 [[TMP11]]
; LV-NEXT:    [[TMP13:%.*]] = icmp ugt ptr [[TMP12]], [[SCEVGEP]]
; LV-NEXT:    [[TMP14:%.*]] = or i1 [[TMP13]], [[MUL_OVERFLOW4]]
; LV-NEXT:    [[TMP15:%.*]] = or i1 [[TMP7]], [[TMP14]]
; LV-NEXT:    br i1 [[TMP15]], label [[FOR_BODY_PH_LVER_ORIG:%.*]], label [[FOR_BODY_PH:%.*]]
; LV:       for.body.ph.lver.orig:
; LV-NEXT:    br label [[FOR_BODY_LVER_ORIG:%.*]]
; LV:       for.body.lver.orig:
; LV-NEXT:    [[IND_LVER_ORIG:%.*]] = phi i64 [ 0, [[FOR_BODY_PH_LVER_ORIG]] ], [ [[INC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[IND1_LVER_ORIG:%.*]] = phi i32 [ [[TRUNCN]], [[FOR_BODY_PH_LVER_ORIG]] ], [ [[DEC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[MUL_LVER_ORIG:%.*]] = mul i32 [[IND1_LVER_ORIG]], 2
; LV-NEXT:    [[MUL_EXT_LVER_ORIG:%.*]] = zext i32 [[MUL_LVER_ORIG]] to i64
; LV-NEXT:    [[ARRAYIDXA_LVER_ORIG:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT_LVER_ORIG]]
; LV-NEXT:    [[LOADA_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[ARRAYIDXB_LVER_ORIG:%.*]] = getelementptr i16, ptr [[B:%.*]], i64 [[IND_LVER_ORIG]]
; LV-NEXT:    [[LOADB_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXB_LVER_ORIG]], align 2
; LV-NEXT:    [[ADD_LVER_ORIG:%.*]] = mul i16 [[LOADA_LVER_ORIG]], [[LOADB_LVER_ORIG]]
; LV-NEXT:    store i16 [[ADD_LVER_ORIG]], ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[INC_LVER_ORIG]] = add nuw nsw i64 [[IND_LVER_ORIG]], 1
; LV-NEXT:    [[DEC_LVER_ORIG]] = sub i32 [[IND1_LVER_ORIG]], 1
; LV-NEXT:    [[EXITCOND_LVER_ORIG:%.*]] = icmp eq i64 [[INC_LVER_ORIG]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND_LVER_ORIG]], label [[FOR_END_LOOPEXIT:%.*]], label [[FOR_BODY_LVER_ORIG]]
; LV:       for.body.ph:
; LV-NEXT:    br label [[FOR_BODY:%.*]]
; LV:       for.body:
; LV-NEXT:    [[IND:%.*]] = phi i64 [ 0, [[FOR_BODY_PH]] ], [ [[INC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[IND1:%.*]] = phi i32 [ [[TRUNCN]], [[FOR_BODY_PH]] ], [ [[DEC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[MUL:%.*]] = mul i32 [[IND1]], 2
; LV-NEXT:    [[MUL_EXT:%.*]] = zext i32 [[MUL]] to i64
; LV-NEXT:    [[ARRAYIDXA:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT]]
; LV-NEXT:    [[LOADA:%.*]] = load i16, ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[ARRAYIDXB:%.*]] = getelementptr i16, ptr [[B]], i64 [[IND]]
; LV-NEXT:    [[LOADB:%.*]] = load i16, ptr [[ARRAYIDXB]], align 2
; LV-NEXT:    [[ADD:%.*]] = mul i16 [[LOADA]], [[LOADB]]
; LV-NEXT:    store i16 [[ADD]], ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[INC]] = add nuw nsw i64 [[IND]], 1
; LV-NEXT:    [[DEC]] = sub i32 [[IND1]], 1
; LV-NEXT:    [[EXITCOND:%.*]] = icmp eq i64 [[INC]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND]], label [[FOR_END_LOOPEXIT5:%.*]], label [[FOR_BODY]]
; LV:       for.end.loopexit:
; LV-NEXT:    br label [[FOR_END:%.*]]
; LV:       for.end.loopexit5:
; LV-NEXT:    br label [[FOR_END]]
; LV:       for.end:
; LV-NEXT:    ret void
;
  ptr noalias %b, i64 %N) {
entry:
  %TruncN = trunc i64 %N to i32
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %ind = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %ind1 = phi i32 [ %TruncN, %entry ], [ %dec, %for.body ]

  %mul = mul i32 %ind1, 2
  %mul_ext = zext i32 %mul to i64

  %arrayidxA = getelementptr i16, ptr %a, i64 %mul_ext
  %loadA = load i16, ptr %arrayidxA, align 2

  %arrayidxB = getelementptr i16, ptr %b, i64 %ind
  %loadB = load i16, ptr %arrayidxB, align 2

  %add = mul i16 %loadA, %loadB

  store i16 %add, ptr %arrayidxA, align 2

  %inc = add nuw nsw i64 %ind, 1
  %dec = sub i32 %ind1, 1

  %exitcond = icmp eq i64 %inc, %N
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

; We replicate the tests above, but this time sign extend 2 * index instead
; of zero extending it.

; The expression for %mul_ext as analyzed by SCEV is
;     i64 (sext i32 {0,+,2}<%for.body> to i64)
; We have added the nssw flag to turn this expression into the following SCEV:
;     i64 {0,+,2}<%for.body>

define void @f3(ptr noalias %a,
; LV-LABEL: @f3(
; LV-NEXT:  for.body.lver.check:
; LV-NEXT:    [[TMP0:%.*]] = add i64 [[N:%.*]], -1
; LV-NEXT:    [[TMP1:%.*]] = trunc i64 [[TMP0]] to i32
; LV-NEXT:    [[MUL1:%.*]] = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 2, i32 [[TMP1]])
; LV-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i32, i1 } [[MUL1]], 0
; LV-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i32, i1 } [[MUL1]], 1
; LV-NEXT:    [[TMP2:%.*]] = icmp slt i32 [[MUL_RESULT]], 0
; LV-NEXT:    [[TMP3:%.*]] = or i1 [[TMP2]], [[MUL_OVERFLOW]]
; LV-NEXT:    [[TMP4:%.*]] = icmp ugt i64 [[TMP0]], 4294967295
; LV-NEXT:    [[TMP5:%.*]] = or i1 [[TMP3]], [[TMP4]]
; LV-NEXT:    [[MUL2:%.*]] = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 4, i64 [[TMP0]])
; LV-NEXT:    [[MUL_RESULT3:%.*]] = extractvalue { i64, i1 } [[MUL2]], 0
; LV-NEXT:    [[MUL_OVERFLOW4:%.*]] = extractvalue { i64, i1 } [[MUL2]], 1
; LV-NEXT:    [[TMP6:%.*]] = sub i64 0, [[MUL_RESULT3]]
; LV-NEXT:    [[TMP7:%.*]] = getelementptr i8, ptr [[A:%.*]], i64 [[MUL_RESULT3]]
; LV-NEXT:    [[TMP8:%.*]] = icmp ult ptr [[TMP7]], [[A]]
; LV-NEXT:    [[TMP9:%.*]] = or i1 [[TMP8]], [[MUL_OVERFLOW4]]
; LV-NEXT:    [[TMP10:%.*]] = or i1 [[TMP5]], [[TMP9]]
; LV-NEXT:    br i1 [[TMP10]], label [[FOR_BODY_PH_LVER_ORIG:%.*]], label [[FOR_BODY_PH:%.*]]
; LV:       for.body.ph.lver.orig:
; LV-NEXT:    br label [[FOR_BODY_LVER_ORIG:%.*]]
; LV:       for.body.lver.orig:
; LV-NEXT:    [[IND_LVER_ORIG:%.*]] = phi i64 [ 0, [[FOR_BODY_PH_LVER_ORIG]] ], [ [[INC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[IND1_LVER_ORIG:%.*]] = phi i32 [ 0, [[FOR_BODY_PH_LVER_ORIG]] ], [ [[INC1_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[MUL_LVER_ORIG:%.*]] = mul i32 [[IND1_LVER_ORIG]], 2
; LV-NEXT:    [[MUL_EXT_LVER_ORIG:%.*]] = sext i32 [[MUL_LVER_ORIG]] to i64
; LV-NEXT:    [[ARRAYIDXA_LVER_ORIG:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT_LVER_ORIG]]
; LV-NEXT:    [[LOADA_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[ARRAYIDXB_LVER_ORIG:%.*]] = getelementptr i16, ptr [[B:%.*]], i64 [[IND_LVER_ORIG]]
; LV-NEXT:    [[LOADB_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXB_LVER_ORIG]], align 2
; LV-NEXT:    [[ADD_LVER_ORIG:%.*]] = mul i16 [[LOADA_LVER_ORIG]], [[LOADB_LVER_ORIG]]
; LV-NEXT:    store i16 [[ADD_LVER_ORIG]], ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[INC_LVER_ORIG]] = add nuw nsw i64 [[IND_LVER_ORIG]], 1
; LV-NEXT:    [[INC1_LVER_ORIG]] = add i32 [[IND1_LVER_ORIG]], 1
; LV-NEXT:    [[EXITCOND_LVER_ORIG:%.*]] = icmp eq i64 [[INC_LVER_ORIG]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND_LVER_ORIG]], label [[FOR_END_LOOPEXIT:%.*]], label [[FOR_BODY_LVER_ORIG]]
; LV:       for.body.ph:
; LV-NEXT:    br label [[FOR_BODY:%.*]]
; LV:       for.body:
; LV-NEXT:    [[IND:%.*]] = phi i64 [ 0, [[FOR_BODY_PH]] ], [ [[INC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[IND1:%.*]] = phi i32 [ 0, [[FOR_BODY_PH]] ], [ [[INC1:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[MUL:%.*]] = mul i32 [[IND1]], 2
; LV-NEXT:    [[MUL_EXT:%.*]] = sext i32 [[MUL]] to i64
; LV-NEXT:    [[ARRAYIDXA:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT]]
; LV-NEXT:    [[LOADA:%.*]] = load i16, ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[ARRAYIDXB:%.*]] = getelementptr i16, ptr [[B]], i64 [[IND]]
; LV-NEXT:    [[LOADB:%.*]] = load i16, ptr [[ARRAYIDXB]], align 2
; LV-NEXT:    [[ADD:%.*]] = mul i16 [[LOADA]], [[LOADB]]
; LV-NEXT:    store i16 [[ADD]], ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[INC]] = add nuw nsw i64 [[IND]], 1
; LV-NEXT:    [[INC1]] = add i32 [[IND1]], 1
; LV-NEXT:    [[EXITCOND:%.*]] = icmp eq i64 [[INC]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND]], label [[FOR_END_LOOPEXIT5:%.*]], label [[FOR_BODY]]
; LV:       for.end.loopexit:
; LV-NEXT:    br label [[FOR_END:%.*]]
; LV:       for.end.loopexit5:
; LV-NEXT:    br label [[FOR_END]]
; LV:       for.end:
; LV-NEXT:    ret void
;
  ptr noalias %b, i64 %N) {
entry:
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %ind = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %ind1 = phi i32 [ 0, %entry ], [ %inc1, %for.body ]

  %mul = mul i32 %ind1, 2
  %mul_ext = sext i32 %mul to i64

  %arrayidxA = getelementptr i16, ptr %a, i64 %mul_ext
  %loadA = load i16, ptr %arrayidxA, align 2

  %arrayidxB = getelementptr i16, ptr %b, i64 %ind
  %loadB = load i16, ptr %arrayidxB, align 2

  %add = mul i16 %loadA, %loadB

  store i16 %add, ptr %arrayidxA, align 2

  %inc = add nuw nsw i64 %ind, 1
  %inc1 = add i32 %ind1, 1

  %exitcond = icmp eq i64 %inc, %N
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

define void @f4(ptr noalias %a,
; LV-LABEL: @f4(
; LV-NEXT:  for.body.lver.check:
; LV-NEXT:    [[TRUNCN:%.*]] = trunc i64 [[N:%.*]] to i32
; LV-NEXT:    [[TMP0:%.*]] = add i64 [[N]], -1
; LV-NEXT:    [[TMP1:%.*]] = shl i32 [[TRUNCN]], 1
; LV-NEXT:    [[TMP2:%.*]] = trunc i64 [[TMP0]] to i32
; LV-NEXT:    [[MUL1:%.*]] = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 2, i32 [[TMP2]])
; LV-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i32, i1 } [[MUL1]], 0
; LV-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i32, i1 } [[MUL1]], 1
; LV-NEXT:    [[TMP3:%.*]] = sub i32 [[TMP1]], [[MUL_RESULT]]
; LV-NEXT:    [[TMP4:%.*]] = icmp sgt i32 [[TMP3]], [[TMP1]]
; LV-NEXT:    [[TMP5:%.*]] = or i1 [[TMP4]], [[MUL_OVERFLOW]]
; LV-NEXT:    [[TMP6:%.*]] = icmp ugt i64 [[TMP0]], 4294967295
; LV-NEXT:    [[TMP7:%.*]] = or i1 [[TMP5]], [[TMP6]]
; LV-NEXT:    [[TMP8:%.*]] = sext i32 [[TMP1]] to i64
; LV-NEXT:    [[TMP9:%.*]] = shl nsw i64 [[TMP8]], 1
; LV-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[A:%.*]], i64 [[TMP9]]
; LV-NEXT:    [[MUL2:%.*]] = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 4, i64 [[TMP0]])
; LV-NEXT:    [[MUL_RESULT3:%.*]] = extractvalue { i64, i1 } [[MUL2]], 0
; LV-NEXT:    [[MUL_OVERFLOW4:%.*]] = extractvalue { i64, i1 } [[MUL2]], 1
; LV-NEXT:    [[TMP10:%.*]] = sub i64 0, [[MUL_RESULT3]]
; LV-NEXT:    [[TMP11:%.*]] = getelementptr i8, ptr [[SCEVGEP]], i64 [[TMP10]]
; LV-NEXT:    [[TMP12:%.*]] = icmp ugt ptr [[TMP11]], [[SCEVGEP]]
; LV-NEXT:    [[TMP13:%.*]] = or i1 [[TMP12]], [[MUL_OVERFLOW4]]
; LV-NEXT:    [[TMP14:%.*]] = or i1 [[TMP7]], [[TMP13]]
; LV-NEXT:    br i1 [[TMP14]], label [[FOR_BODY_PH_LVER_ORIG:%.*]], label [[FOR_BODY_PH:%.*]]
; LV:       for.body.ph.lver.orig:
; LV-NEXT:    br label [[FOR_BODY_LVER_ORIG:%.*]]
; LV:       for.body.lver.orig:
; LV-NEXT:    [[IND_LVER_ORIG:%.*]] = phi i64 [ 0, [[FOR_BODY_PH_LVER_ORIG]] ], [ [[INC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[IND1_LVER_ORIG:%.*]] = phi i32 [ [[TRUNCN]], [[FOR_BODY_PH_LVER_ORIG]] ], [ [[DEC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[MUL_LVER_ORIG:%.*]] = mul i32 [[IND1_LVER_ORIG]], 2
; LV-NEXT:    [[MUL_EXT_LVER_ORIG:%.*]] = sext i32 [[MUL_LVER_ORIG]] to i64
; LV-NEXT:    [[ARRAYIDXA_LVER_ORIG:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT_LVER_ORIG]]
; LV-NEXT:    [[LOADA_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[ARRAYIDXB_LVER_ORIG:%.*]] = getelementptr i16, ptr [[B:%.*]], i64 [[IND_LVER_ORIG]]
; LV-NEXT:    [[LOADB_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXB_LVER_ORIG]], align 2
; LV-NEXT:    [[ADD_LVER_ORIG:%.*]] = mul i16 [[LOADA_LVER_ORIG]], [[LOADB_LVER_ORIG]]
; LV-NEXT:    store i16 [[ADD_LVER_ORIG]], ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[INC_LVER_ORIG]] = add nuw nsw i64 [[IND_LVER_ORIG]], 1
; LV-NEXT:    [[DEC_LVER_ORIG]] = sub i32 [[IND1_LVER_ORIG]], 1
; LV-NEXT:    [[EXITCOND_LVER_ORIG:%.*]] = icmp eq i64 [[INC_LVER_ORIG]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND_LVER_ORIG]], label [[FOR_END_LOOPEXIT:%.*]], label [[FOR_BODY_LVER_ORIG]]
; LV:       for.body.ph:
; LV-NEXT:    br label [[FOR_BODY:%.*]]
; LV:       for.body:
; LV-NEXT:    [[IND:%.*]] = phi i64 [ 0, [[FOR_BODY_PH]] ], [ [[INC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[IND1:%.*]] = phi i32 [ [[TRUNCN]], [[FOR_BODY_PH]] ], [ [[DEC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[MUL:%.*]] = mul i32 [[IND1]], 2
; LV-NEXT:    [[MUL_EXT:%.*]] = sext i32 [[MUL]] to i64
; LV-NEXT:    [[ARRAYIDXA:%.*]] = getelementptr i16, ptr [[A]], i64 [[MUL_EXT]]
; LV-NEXT:    [[LOADA:%.*]] = load i16, ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[ARRAYIDXB:%.*]] = getelementptr i16, ptr [[B]], i64 [[IND]]
; LV-NEXT:    [[LOADB:%.*]] = load i16, ptr [[ARRAYIDXB]], align 2
; LV-NEXT:    [[ADD:%.*]] = mul i16 [[LOADA]], [[LOADB]]
; LV-NEXT:    store i16 [[ADD]], ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[INC]] = add nuw nsw i64 [[IND]], 1
; LV-NEXT:    [[DEC]] = sub i32 [[IND1]], 1
; LV-NEXT:    [[EXITCOND:%.*]] = icmp eq i64 [[INC]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND]], label [[FOR_END_LOOPEXIT5:%.*]], label [[FOR_BODY]]
; LV:       for.end.loopexit:
; LV-NEXT:    br label [[FOR_END:%.*]]
; LV:       for.end.loopexit5:
; LV-NEXT:    br label [[FOR_END]]
; LV:       for.end:
; LV-NEXT:    ret void
;
  ptr noalias %b, i64 %N) {
entry:
  %TruncN = trunc i64 %N to i32
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %ind = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %ind1 = phi i32 [ %TruncN, %entry ], [ %dec, %for.body ]

  %mul = mul i32 %ind1, 2
  %mul_ext = sext i32 %mul to i64

  %arrayidxA = getelementptr i16, ptr %a, i64 %mul_ext
  %loadA = load i16, ptr %arrayidxA, align 2

  %arrayidxB = getelementptr i16, ptr %b, i64 %ind
  %loadB = load i16, ptr %arrayidxB, align 2

  %add = mul i16 %loadA, %loadB

  store i16 %add, ptr %arrayidxA, align 2

  %inc = add nuw nsw i64 %ind, 1
  %dec = sub i32 %ind1, 1

  %exitcond = icmp eq i64 %inc, %N
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}

; The following function is similar to the one above, but has the GEP
; to pointer %A inbounds. The index %mul doesn't have the nsw flag.
; This means that the SCEV expression for %mul can wrap and we need
; a SCEV predicate to continue analysis.
;
; We can still analyze this by adding the required no wrap SCEV predicates.

define void @f5(ptr noalias %a,
; LV-LABEL: @f5(
; LV-NEXT:  for.body.lver.check:
; LV-NEXT:    [[TRUNCN:%.*]] = trunc i64 [[N:%.*]] to i32
; LV-NEXT:    [[TMP0:%.*]] = add i64 [[N]], -1
; LV-NEXT:    [[TMP1:%.*]] = shl i32 [[TRUNCN]], 1
; LV-NEXT:    [[TMP2:%.*]] = trunc i64 [[TMP0]] to i32
; LV-NEXT:    [[MUL1:%.*]] = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 2, i32 [[TMP2]])
; LV-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i32, i1 } [[MUL1]], 0
; LV-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i32, i1 } [[MUL1]], 1
; LV-NEXT:    [[TMP3:%.*]] = sub i32 [[TMP1]], [[MUL_RESULT]]
; LV-NEXT:    [[TMP4:%.*]] = icmp sgt i32 [[TMP3]], [[TMP1]]
; LV-NEXT:    [[TMP5:%.*]] = or i1 [[TMP4]], [[MUL_OVERFLOW]]
; LV-NEXT:    [[TMP6:%.*]] = icmp ugt i64 [[TMP0]], 4294967295
; LV-NEXT:    [[TMP14:%.*]] = or i1 [[TMP5]], [[TMP6]]
; LV-NEXT:    br i1 [[TMP14]], label [[FOR_BODY_PH_LVER_ORIG:%.*]], label [[FOR_BODY_PH:%.*]]
; LV:       for.body.ph.lver.orig:
; LV-NEXT:    br label [[FOR_BODY_LVER_ORIG:%.*]]
; LV:       for.body.lver.orig:
; LV-NEXT:    [[IND_LVER_ORIG:%.*]] = phi i64 [ 0, [[FOR_BODY_PH_LVER_ORIG]] ], [ [[INC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[IND1_LVER_ORIG:%.*]] = phi i32 [ [[TRUNCN]], [[FOR_BODY_PH_LVER_ORIG]] ], [ [[DEC_LVER_ORIG:%.*]], [[FOR_BODY_LVER_ORIG]] ]
; LV-NEXT:    [[MUL_LVER_ORIG:%.*]] = mul i32 [[IND1_LVER_ORIG]], 2
; LV-NEXT:    [[ARRAYIDXA_LVER_ORIG:%.*]] = getelementptr inbounds i16, ptr [[A:%.*]], i32 [[MUL_LVER_ORIG]]
; LV-NEXT:    [[LOADA_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[ARRAYIDXB_LVER_ORIG:%.*]] = getelementptr inbounds i16, ptr [[B:%.*]], i64 [[IND_LVER_ORIG]]
; LV-NEXT:    [[LOADB_LVER_ORIG:%.*]] = load i16, ptr [[ARRAYIDXB_LVER_ORIG]], align 2
; LV-NEXT:    [[ADD_LVER_ORIG:%.*]] = mul i16 [[LOADA_LVER_ORIG]], [[LOADB_LVER_ORIG]]
; LV-NEXT:    store i16 [[ADD_LVER_ORIG]], ptr [[ARRAYIDXA_LVER_ORIG]], align 2
; LV-NEXT:    [[INC_LVER_ORIG]] = add nuw nsw i64 [[IND_LVER_ORIG]], 1
; LV-NEXT:    [[DEC_LVER_ORIG]] = sub i32 [[IND1_LVER_ORIG]], 1
; LV-NEXT:    [[EXITCOND_LVER_ORIG:%.*]] = icmp eq i64 [[INC_LVER_ORIG]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND_LVER_ORIG]], label [[FOR_END_LOOPEXIT:%.*]], label [[FOR_BODY_LVER_ORIG]]
; LV:       for.body.ph:
; LV-NEXT:    br label [[FOR_BODY:%.*]]
; LV:       for.body:
; LV-NEXT:    [[IND:%.*]] = phi i64 [ 0, [[FOR_BODY_PH]] ], [ [[INC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[IND1:%.*]] = phi i32 [ [[TRUNCN]], [[FOR_BODY_PH]] ], [ [[DEC:%.*]], [[FOR_BODY]] ]
; LV-NEXT:    [[MUL:%.*]] = mul i32 [[IND1]], 2
; LV-NEXT:    [[ARRAYIDXA:%.*]] = getelementptr inbounds i16, ptr [[A]], i32 [[MUL]]
; LV-NEXT:    [[LOADA:%.*]] = load i16, ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[ARRAYIDXB:%.*]] = getelementptr inbounds i16, ptr [[B]], i64 [[IND]]
; LV-NEXT:    [[LOADB:%.*]] = load i16, ptr [[ARRAYIDXB]], align 2
; LV-NEXT:    [[ADD:%.*]] = mul i16 [[LOADA]], [[LOADB]]
; LV-NEXT:    store i16 [[ADD]], ptr [[ARRAYIDXA]], align 2
; LV-NEXT:    [[INC]] = add nuw nsw i64 [[IND]], 1
; LV-NEXT:    [[DEC]] = sub i32 [[IND1]], 1
; LV-NEXT:    [[EXITCOND:%.*]] = icmp eq i64 [[INC]], [[N]]
; LV-NEXT:    br i1 [[EXITCOND]], label [[FOR_END_LOOPEXIT5:%.*]], label [[FOR_BODY]]
; LV:       for.end.loopexit:
; LV-NEXT:    br label [[FOR_END:%.*]]
; LV:       for.end.loopexit2:
; LV-NEXT:    br label [[FOR_END]]
; LV:       for.end:
; LV-NEXT:    ret void
;
  ptr noalias %b, i64 %N) {
entry:
  %TruncN = trunc i64 %N to i32
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %ind = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %ind1 = phi i32 [ %TruncN, %entry ], [ %dec, %for.body ]

  %mul = mul i32 %ind1, 2

  %arrayidxA = getelementptr inbounds i16, ptr %a, i32 %mul
  %loadA = load i16, ptr %arrayidxA, align 2

  %arrayidxB = getelementptr inbounds i16, ptr %b, i64 %ind
  %loadB = load i16, ptr %arrayidxB, align 2

  %add = mul i16 %loadA, %loadB

  store i16 %add, ptr %arrayidxA, align 2

  %inc = add nuw nsw i64 %ind, 1
  %dec = sub i32 %ind1, 1

  %exitcond = icmp eq i64 %inc, %N
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret void
}
